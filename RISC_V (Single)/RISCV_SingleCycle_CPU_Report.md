# Báo cáo Project: RISC-V RV32I Single-Cycle CPU

> Trạng thái: Đang phát triển — đã hoàn thành R-type, Immediate Generator, tích hợp I-type ALU (ADDI...)
> Kiến trúc: Single-cycle, chuẩn bị nền tảng để mở rộng lên Pipeline 5 tầng

---

## 1. Tổng quan project

Project xây dựng một CPU RISC-V RV32I theo kiến trúc **single-cycle** (mỗi lệnh thực thi trọn vẹn trong đúng 1 chu kỳ clock), bằng Verilog, mô phỏng trên Vivado Simulator.

Mục tiêu cuối cùng: hoàn thiện đầy đủ tập lệnh RV32I cơ bản, sau đó chuyển đổi kiến trúc sang **pipeline 5 tầng** (IF-ID-EX-MEM-WB) kèm xử lý hazard (forwarding, stall, flush).

---

## 2. Cấu trúc thư mục / module hiện tại

```
top.v                   — Module gốc, ráp toàn bộ datapath
├── ripple32bit.v        — Bộ cộng/trừ 32-bit (dùng cho PC+4 và ALU ADD/SUB)
├── program_counter.v    — Thanh ghi PC
├── instruction_memory.v — ROM chứa chương trình (đọc từ file .mem)
├── imm_gen.v             — Sinh giá trị immediate từ instruction (MỚI)
├── control_unit.v        — Giải mã opcode/funct3/funct7 → tín hiệu điều khiển
├── register_file.v       — 32 thanh ghi x0-x31
└── alu.v                 — Đơn vị tính toán số học/logic (12 phép toán)
```

---

## 3. Sơ đồ luồng dữ liệu (Datapath) hiện tại

```
                    ┌─────────────┐
              ┌────►│ ripple32bit │  pc + 4
              │     │  (pc_adder) │──────┐
              │     └─────────────┘      │
              │                          ▼
        ┌─────┴──────┐            ┌──────────┐
        │   PC_out   │◄───────────│  pc_next │
        │(program_   │   pc_in    └──────────┘
        │ counter)   │
        └─────┬──────┘
              │ pc_current
              ▼
     ┌─────────────────┐
     │ instruction_     │
     │ memory (ROM)     │──────► instruction[31:0]
     └─────────────────┘              │
                     ┌─────────────────┼─────────────────┬─────────────┐
                     ▼                 ▼                 ▼             ▼
             ┌───────────────┐ ┌──────────────┐  ┌──────────────┐ ┌─────────┐
             │  control_unit │ │  imm_gen     │  │ register_file│ │ (funct  │
             │ (giải mã opcode│ │ (sinh imm    │  │ đọc rs1, rs2 │ │  fields)│
             │  funct3,funct7)│ │  32-bit)      │  │              │ └─────────┘
             └───────┬───────┘ └──────┬───────┘  └──────┬───────┘
                     │                │                  │
             reg_write, alu_src,   imm_value        reg_data1, reg_data2
             alu_ctrl, mem_read,        │                  │
             mem_write, branch, jump    │                  │
                     │                  │                  │
                     │           ┌──────▼──────┐           │
                     │           │  MUX alu_b   │◄──────────┘ (reg_data2)
                     │           │ alu_src?     │
                     │           │ imm : reg    │
                     │           └──────┬──────┘
                     │                  │ alu_b_in
                     │                  ▼
                     │           ┌──────────────┐
                     └──────────►│     ALU      │◄──── reg_data1 (a)
                        alu_ctrl │ (12 phép toán)│
                                 └──────┬───────┘
                                        │ alu_result
                                        ▼
                              ┌──────────────────┐
                              │ register_file.d   │  (ghi ngược vào rd)
                              │ (write-back)      │
                              └──────────────────┘
                                        │
                                        ▼
                                  out_result (output CPU)
```

---

## 4. Chi tiết từng module

### 4.1. `ripple32bit.v` — Bộ cộng/trừ 32-bit gợn sóng

- Dùng chuỗi `full_adder` nối tiếp (ripple carry).
- Hỗ trợ cả cộng và trừ qua kỹ thuật XOR đầu vào B với tín hiệu `sub` (two's complement).
- Dùng ở 2 nơi: tính `pc + 4` và tính `a + b` / `a - b` trong ALU.

```verilog
assign b_xor = b ^ {N{sub}};
full_adder fa (.a(a[0]), .b(b_xor[0]), .c_in(sub), .s(s[0]), .c_out(w[0]));
```

### 4.2. `program_counter.v` — Thanh ghi PC

**Lỗi đã phát hiện và sửa**: bản gốc khi `reset` gán `pc_out <= pc_in`, trong khi `pc_in` (= `pc_next`) lại phụ thuộc ngược vào `pc_out` qua bộ cộng tổ hợp → tạo vòng lặp X (giá trị chưa xác định) không bao giờ thoát được.

**Đã sửa**:
```verilog
always@(posedge clk)
    if (reset) 
        pc_out <= 32'd0;   // reset về giá trị cố định, không phải pc_in
    else 
        pc_out <= pc_in;
```

### 4.3. `instruction_memory.v` — Bộ nhớ lệnh (ROM)

- Mảng `reg [31:0] RAM [0:63]`, nạp dữ liệu bằng `$readmemh("instruction_memory_testbench.mem", RAM)`.
- Đọc tổ hợp: `readData = RAM[pc_in[5:2]]`.

**Vấn đề đã gặp**: nếu file `.mem` có ít lệnh hơn số chu kỳ mô phỏng, PC sẽ chạy vượt quá vùng RAM có dữ liệu hợp lệ → đọc phải ô nhớ chưa khởi tạo (X) → toàn bộ pipeline phía sau bị X theo.

**Giải pháp áp dụng**: giới hạn thời gian mô phỏng testbench khớp với số lệnh thực tế trong file `.mem`.

### 4.4. `imm_gen.v` — Sinh giá trị Immediate (MỚI HOÀN THÀNH)

Nhiệm vụ: gom các mảnh bit immediate bị ISA "xé lẻ" trong instruction (do phải nhường vị trí cố định cho `rs1`, `rs2`, `funct3`), ghép lại thành 1 giá trị 32-bit đã sign-extend.

| Định dạng | Cách trích xuất | Sign-extend |
|---|---|---|
| I-type | `instruction[31:20]` (liền mạch) | 20 bit từ `instruction[31]` |
| S-type | Gộp `instruction[31:25]` + `instruction[11:7]` | 20 bit |
| B-type | Gộp `instr[31], instr[7], instr[30:25], instr[11:8], 1'b0` | 19 bit |
| U-type | `instruction[31:12]` + 12 bit `0` | Không cần |
| J-type | Gộp `instr[31], instr[19:12], instr[20], instr[30:21], 1'b0` | 11 bit |
| R-type (default) | Không có immediate | `imm_out = 0` |

**Ví dụ đã kiểm chứng**:
- `addi x1, x0, 10` → encoding `0x00A00093` → `imm_out = 0x0000000A = 10` ✓
- `addi x5, x2, -3` → encoding `0xFFD10293` → `imm_out = 0xFFFFFFFD = -3` ✓
- `add x1, x2, x3` (R-type) → `imm_out = 0` (không dùng tới, mux sẽ bỏ qua)

### 4.5. `control_unit.v` — Đơn vị điều khiển

Giải mã `opcode` (7 bit) + `funct3` (3 bit) + `funct7[5]` (1 bit) → xuất ra các tín hiệu điều khiển toàn bộ datapath.

**Bảng tín hiệu điều khiển theo opcode**:

| opcode | Loại lệnh | reg_write | alu_src | mem_read | mem_write | mem_to_reg | branch | jump |
|---|---|---|---|---|---|---|---|---|
| `0110011` | R-type | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `0010011` | I-type ALU (ADDI...) | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `0000011` | I-type Load (LW...) *(chưa hiện thực)* | 1 | 1 | 1 | 0 | 1 | 0 | 0 |
| `0100011` | S-type (SW...) *(chưa hiện thực)* | 0 | 1 | 0 | 1 | 0 | 0 | 0 |
| `1100011` | B-type (BEQ...) *(chưa hiện thực)* | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| `1101111` | J-type (JAL) *(chưa hiện thực)* | 1 | X | 0 | 0 | 0 | 0 | 1 |

**Bảng ALU control (4-bit, đã mở rộng từ 3-bit ban đầu)**:

| alu_ctrl | Phép toán |
|---|---|
| `0000` | pass A |
| `0001` | NOT |
| `0010` | AND |
| `0011` | OR |
| `0100` | XOR |
| `0101` | ADD |
| `0110` | SUB |
| `0111` | SLL |
| `1000` | SRL |
| `1001` | SRA |
| `1010` | SLT |
| `1011` | SLTU |

### 4.6. `register_file.v` — Tệp thanh ghi

- 32 thanh ghi 32-bit, đọc tổ hợp (`rd1`, `rd2`), ghi đồng bộ theo cạnh clock.
- `x0` luôn trả về `0` bất kể nội dung `mem[0]` (không cho ghi vào x0):
```verilog
assign rd1 = (ra1==5'd0) ? 32'd0 : mem[ra1];
```
- Reset đưa toàn bộ 32 thanh ghi về `0` (quyết định thiết kế mô phỏng — CPU thật chỉ đảm bảo x0=0, các thanh ghi khác undefined sau reset, cần boot code nạp giá trị).

### 4.7. `alu.v` — Đơn vị tính toán (đã mở rộng, đã test xong)

- Mở rộng từ 3-bit `sel` (chỉ 8 phép) lên **4-bit `sel`** (12 phép toán) để đủ hỗ trợ RV32I.
- Bổ sung: SLL, SRL, SRA (dịch bit), SLT, SLTU (so sánh có dấu/không dấu).
- Bổ sung output `zero_flag` (chuẩn bị cho Branch).
- **Đã test xong** bằng self-checking testbench (`function` làm reference model, `task` để gọi và so sánh), test cả trường hợp directed và random (`$urandom`).

### 4.8. `top.v` — Ráp toàn bộ datapath

Cập nhật mới nhất, đã tích hợp:
```verilog
imm_gen ImmGen (.instruction(instruction), .imm_out(imm_value));

assign alu_b_in = alu_src_sig ? imm_value : reg_data2;

alu ALU(.a(reg_data1), .b(alu_b_in), .sel(alu_ctrl_sig), .c(alu_result), .zero_flag(alu_zero_flag));
```

**Chưa có trong `top.v` hiện tại** (dự kiến thêm ở bước LW/SW): `data_memory`, mux write-back (chọn giữa `alu_result` và `mem_read_data`).

---

## 5. Luồng dữ liệu cho 1 lệnh cụ thể — Ví dụ minh họa

### Lệnh: `addi x5, x2, -3` (encoding `0xFFD10293`)

```
Chu kỳ clock hiện tại:
1. PC trỏ tới địa chỉ chứa lệnh này → instruction_memory trả về 0xFFD10293
2. control_unit đọc opcode=0010011 → set: reg_write=1, alu_src=1, alu_ctrl=0101(ADD)
3. imm_gen đọc opcode=0010011 → sign-extend instruction[31:20] → imm_out = -3
4. register_file đọc rs1=x2 → reg_data1 = (giá trị hiện có trong x2, VD: 10)
5. MUX: vì alu_src=1 → alu_b_in = imm_value = -3 (bỏ qua reg_data2)
6. ALU: c = reg_data1 + alu_b_in = 10 + (-3) = 7
7. register_file: ghi alu_result=7 vào rd=x5 (có hiệu lực ở cạnh clock kế tiếp)
```

### Lệnh R-type: `add x1, x2, x3`

```
1. control_unit đọc opcode=0110011 → reg_write=1, alu_src=0, alu_ctrl phụ thuộc funct3/funct7
2. imm_gen: opcode không khớp nhánh nào → rơi vào default → imm_out=0 (không dùng tới)
3. MUX: alu_src=0 → alu_b_in = reg_data2 (bỏ qua imm_value)
4. ALU: c = reg_data1 + reg_data2
5. Ghi kết quả vào rd
```

---

## 6. Chương trình test hiện tại

File `instruction_memory_testbench.mem`:

```
00a00093   // addi x1, x0, 10   → x1 = 10
00500113   // addi x2, x0, 5    → x2 = 5
002081b3   // add  x3, x1, x2   → x3 = 15
40208233   // sub  x4, x1, x2   → x4 = 5
```

**Kết quả mong đợi sau khi chạy hết**: `x1=10, x2=5, x3=15, x4=5`.

Đây là bài test quan trọng vì nó xác nhận: (1) ADDI nạp giá trị đúng, (2) R-type đọc đúng giá trị vừa được ADDI ghi vào (kiểm chứng register file hoạt động đúng qua nhiều lệnh liên tiếp), (3) imm_gen + mux ALU-B hoạt động đúng.

---

## 7. Các lỗi đã phát hiện và sửa trong quá trình phát triển

| # | Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|---|
| 1 | `out_result` ra toàn X | `program_counter` reset gán `pc_out <= pc_in`, tạo vòng lặp phụ thuộc X | Sửa reset về `32'd0` cố định |
| 2 | PC tăng 8 thay vì 4 mỗi chu kỳ | `program_counter` cộng thêm +4 ở nhánh else, trong khi `pc_in` đã là `pc_current+4` từ bên ngoài | Bỏ +4 dư trong nhánh else |
| 3 | `readData` ra X sau vài chu kỳ | PC chạy vượt quá số lệnh có trong file `.mem`, đọc phải vùng RAM chưa khởi tạo | Giới hạn thời gian mô phỏng khớp số lệnh, hoặc lấp NOP vào phần RAM còn lại |
| 4 | `out_result` luôn = 0 dù ALU đúng | Mọi thanh ghi reset về 0, chương trình chỉ có lệnh R-type nên không có cách nạp giá trị khác 0 | Thêm hỗ trợ ADDI (I-type) để nạp giá trị khởi tạo — đúng như CPU thật cần boot code |
| 5 | ALU chỉ có 3-bit `sel`, thiếu nhiều phép toán | Thiết kế ban đầu chỉ có 8 phép, thiếu SLL/SRL/SRA/SLT/SLTU | Mở rộng `sel` lên 4-bit, bổ sung đủ 12 phép theo chuẩn RV32I |
| 6 | Testbench báo lỗi cú pháp port connection | Thiếu dấu `.` trước tên port khi instantiate (`reset(reset)` thay vì `.reset(reset)`) | Thêm dấu `.` đúng cú pháp named port connection |

---

## 8. Phương pháp kiểm thử (Testing methodology)

Áp dụng mô hình **self-checking testbench** cho từng module riêng biệt trước khi ráp hệ thống:

```
DUT (module thật) ──┐
                     ├──► So sánh (task/function) ──► PASS/FAIL
Reference Model ─────┘
(function tính tay)
```

- **`function`**: dùng cho model tham chiếu (reference model) — tính toán thuần túy, không chờ thời gian (VD: `alu_model`, `imm_gen` reference).
- **`task`**: dùng khi cần chờ tín hiệu ổn định sau khi thay đổi input (VD: `#1` chờ mạch tổ hợp settle, hoặc `@(posedge clk)` chờ 1 chu kỳ).
- Kết hợp test **directed** (giá trị cụ thể, dễ kiểm tra tay) và **random** (`$urandom`, `$urandom_range`) để tăng độ phủ.

**Đã áp dụng thành công cho `alu.v`** — test cả 12 phép toán, 3 case directed + 50 case random, dùng `!==` để phát hiện cả giá trị X.

---

## 9. Trạng thái hiện tại (Current status)

| Thành phần | Trạng thái |
|---|---|
| R-type (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU) | ✅ Hoàn thành, ALU đã test |
| Immediate Generator (I/S/B/U/J) | ✅ Hoàn thành, đã kiểm chứng bằng ví dụ tay |
| I-type ALU (ADDI...) | ✅ Đã tích hợp vào `top.v`, đang chờ chạy test cuối |
| I-type Load (LW...) | 🔲 Chưa làm — cần thêm `data_memory.v` |
| S-type (SW...) | 🔲 Chưa làm — cần thêm `data_memory.v` |
| B-type (BEQ, BNE...) | 🔲 Chưa làm — cần thêm branch comparator + mux PC |
| J-type (JAL), JALR | 🔲 Chưa làm — cần thêm mux PC + ghi return address |
| U-type (LUI, AUIPC) | 🔲 Chưa làm |
| Pipeline 5 tầng | 🔲 Chưa bắt đầu — dự kiến sau khi hoàn thiện single-cycle |

---

## 10. Lộ trình tiếp theo (Roadmap)

```
[HIỆN TẠI] ADDI + R-type
     │
     ▼
[TIẾP THEO] LW / SW
     • Thêm module data_memory.v
     • Thêm mux write-back (alu_result vs mem_read_data)
     │
     ▼
BEQ / BNE / BLT / BGE (Branch)
     • Thêm branch comparator (dùng zero_flag / SLT)
     • Thêm mux chọn PC: pc+4 hay pc+imm (branch target)
     │
     ▼
JAL / JALR (Jump)
     • Thêm mux PC cho jump target
     • Ghi return address (pc+4) vào rd
     │
     ▼
LUI / AUIPC (nạp hằng số 32-bit đầy đủ)
     │
     ▼
[GIAI ĐOẠN 2] Chuyển sang Pipeline 5 tầng
     • Tách rõ 5 giai đoạn: IF - ID - EX - MEM - WB
     • Thêm thanh ghi pipeline (IF/ID, ID/EX, EX/MEM, MEM/WB)
     • Hazard Detection Unit (stall cho load-use hazard)
     • Forwarding Unit (giải quyết data hazard)
     • Flush logic (giải quyết control hazard khi branch/jump)
```

---

## 11. Kiến thức nền đã học trong quá trình làm project

- **Instruction formats RV32I**: R/I/S/B/U/J, ý nghĩa và mục đích thiết kế của việc rải bit immediate.
- **SystemVerilog `task` vs `function`**: khi nào dùng loại nào, vai trò của `automatic`, cách truyền tham số (`input`/`output`/`ref`).
- **Kỹ thuật self-checking testbench**: reference model, so sánh `!==` để bắt lỗi X, kết hợp test directed + random.
- **Khái niệm two's complement**: vì sao phép trừ có thể thực hiện bằng bộ cộng qua kỹ thuật XOR + carry-in.
- **Sign-extend vs Zero-extend**: và lý do SRA/SLT cần phân biệt số có dấu/không dấu.

---

*Báo cáo được cập nhật tính đến thời điểm hiện tại của quá trình phát triển. Cập nhật tiếp khi hoàn thành các module mới (data_memory, branch logic...).*
