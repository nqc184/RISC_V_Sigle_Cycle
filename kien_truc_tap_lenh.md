# BÁO CÁO: TẬP LỆNH RISC-V (RV32I) VÀ CÁCH HOẠT ĐỘNG

## 1. Tổng quan kiến trúc

RISC-V RV32I là tập lệnh cơ bản (base instruction set) 32-bit, gồm 6 định dạng lệnh (instruction format): **R, I, S, B, U, J**. Mỗi định dạng có cách sắp xếp bit khác nhau để mã hóa opcode, thanh ghi, và immediate (hằng số).

Tất cả lệnh đều dài **32-bit cố định**, giúp việc fetch và decode đơn giản, dễ pipeline.

### Cấu trúc thanh ghi

- 32 thanh ghi mục đích chung: `x0` đến `x31`, mỗi thanh ghi 32-bit.
- `x0` luôn **cố định = 0** (hardwired), ghi vào x0 không có tác dụng.
- Không có thanh ghi cờ (flags) riêng như x86 — mọi so sánh dùng kết quả trực tiếp từ ALU (ví dụ SLT trả về 0/1).

---

## 2. Sáu định dạng lệnh (Instruction Formats)

```
 31        25 24    20 19    15 14  12 11      7 6      0
R: | funct7  |  rs2   |  rs1   |funct3|   rd    | opcode |
I: |      imm[11:0]   |  rs1   |funct3|   rd    | opcode |
S: | imm[11:5]|  rs2   |  rs1   |funct3|imm[4:0] | opcode |
B: |imm[12,10:5]|rs2   |  rs1   |funct3|imm[4:1,11]|opcode|
U: |            imm[31:12]              |   rd   | opcode |
J: |     imm[20,10:1,11,19:12]          |   rd   | opcode |
```

| Field | Ý nghĩa |
|---|---|
| `opcode` (7 bit) | Xác định loại lệnh (R/I/S/B/U/J) và nhóm lệnh |
| `rd` (5 bit) | Thanh ghi đích (destination register) |
| `funct3` (3 bit) | Phân biệt các lệnh con trong cùng 1 opcode |
| `rs1`, `rs2` (5 bit) | Thanh ghi nguồn 1 và 2 |
| `funct7` (7 bit) | Phân biệt thêm (VD: ADD vs SUB có cùng funct3) |
| `imm` | Hằng số, vị trí và độ dài khác nhau tùy định dạng |

---

## 3. Nhóm lệnh R-type (Register-Register) — opcode `0110011`

Thực hiện phép toán giữa 2 thanh ghi, kết quả ghi vào thanh ghi đích.

| Lệnh | funct3 | funct7[5] | Hoạt động |
|---|---|---|---|
| `ADD`  | 000 | 0 | `rd = rs1 + rs2` |
| `SUB`  | 000 | 1 | `rd = rs1 - rs2` |
| `SLL`  | 001 | 0 | `rd = rs1 << rs2[4:0]` (dịch trái logic) |
| `SLT`  | 010 | 0 | `rd = (rs1 < rs2) ? 1 : 0` (so sánh có dấu) |
| `SLTU` | 011 | 0 | `rd = (rs1 < rs2) ? 1 : 0` (so sánh không dấu) |
| `XOR`  | 100 | 0 | `rd = rs1 ^ rs2` |
| `SRL`  | 101 | 0 | `rd = rs1 >> rs2[4:0]` (dịch phải logic, lấp 0) |
| `SRA`  | 101 | 1 | `rd = rs1 >>> rs2[4:0]` (dịch phải số học, giữ dấu) |
| `OR`   | 110 | 0 | `rd = rs1 \| rs2` |
| `AND`  | 111 | 0 | `rd = rs1 & rs2` |

**Đặc điểm quan trọng**: ADD/SUB và SRL/SRA có cùng `funct3`, chỉ khác nhau ở bit `funct7[5]` (bit 30 của instruction) — đây là lý do control unit cần kiểm tra thêm bit này.

**Ví dụ**: `add x1, x2, x3` → encoding: `funct7=0000000, rs2=x3, rs1=x2, funct3=000, rd=x1, opcode=0110011`.

---

## 4. Nhóm lệnh I-type (Immediate) — 3 nhóm con

### 4.1. I-type ALU — opcode `0010011`

Giống R-type nhưng toán hạng thứ 2 là **hằng số 12-bit** (sign-extend thành 32-bit), không phải thanh ghi.

| Lệnh | funct3 | Hoạt động |
|---|---|---|
| `ADDI`  | 000 | `rd = rs1 + sign_extend(imm)` |
| `SLTI`  | 010 | `rd = (rs1 < imm) ? 1 : 0` (có dấu) |
| `SLTIU` | 011 | `rd = (rs1 < imm) ? 1 : 0` (không dấu) |
| `XORI`  | 100 | `rd = rs1 ^ imm` |
| `ORI`   | 110 | `rd = rs1 \| imm` |
| `ANDI`  | 111 | `rd = rs1 & imm` |
| `SLLI`  | 001 | `rd = rs1 << shamt` (shamt = imm[4:0]) |
| `SRLI`  | 101 (funct7[5]=0) | `rd = rs1 >> shamt` |
| `SRAI`  | 101 (funct7[5]=1) | `rd = rs1 >>> shamt` |

**Lưu ý riêng SLLI/SRLI/SRAI**: vì shift amount chỉ cần 5 bit (0-31), nên 7 bit cao của trường immediate (imm[11:5]) được dùng làm `funct7` để phân biệt SRLI/SRAI, giống cách R-type phân biệt ADD/SUB.

**Vai trò đặc biệt của ADDI**: đây là lệnh dùng để **nạp giá trị khởi tạo** vào thanh ghi — vì sau reset mọi thanh ghi đều = 0 (hoặc undefined trên phần cứng thật), `ADDI rd, x0, imm` (cộng với x0=0) chính là cách phổ biến nhất để đưa 1 hằng số vào thanh ghi.

### 4.2. I-type Load — opcode `0000011`

Đọc dữ liệu từ bộ nhớ vào thanh ghi. Địa chỉ = `rs1 + sign_extend(imm)`.

| Lệnh | funct3 | Hoạt động |
|---|---|---|
| `LB`  | 000 | Đọc 1 byte, sign-extend thành 32-bit |
| `LH`  | 001 | Đọc 2 byte (halfword), sign-extend |
| `LW`  | 010 | Đọc 4 byte (word) — đầy đủ 32-bit |
| `LBU` | 100 | Đọc 1 byte, zero-extend (không dấu) |
| `LHU` | 101 | Đọc 2 byte, zero-extend (không dấu) |

### 4.3. JALR — opcode `1100111`

`Jump And Link Register`: nhảy tới địa chỉ tính từ thanh ghi + immediate.

```
target = (rs1 + imm) & ~1     // bit 0 luôn set về 0
rd     = pc + 4                // lưu địa chỉ quay về (return address)
pc     = target
```

Dùng để hiện thực lời gọi hàm gián tiếp (function pointer, return khỏi hàm).

---

## 5. Nhóm lệnh S-type (Store) — opcode `0100011`

Ghi dữ liệu từ thanh ghi vào bộ nhớ. Địa chỉ = `rs1 + sign_extend(imm)`. Immediate bị tách thành 2 mảnh (imm[11:5] và imm[4:0]) vì phải nhường chỗ cho `rs2` trong encoding, nhưng khi ghép lại vẫn là 1 số 12-bit bình thường.

| Lệnh | funct3 | Hoạt động |
|---|---|---|
| `SB` | 000 | Ghi 1 byte thấp của `rs2` vào bộ nhớ |
| `SH` | 001 | Ghi 2 byte thấp của `rs2` |
| `SW` | 010 | Ghi đủ 4 byte (32-bit) của `rs2` |

**Ví dụ**: `sw x1, 8(x2)` → ghi giá trị `x1` vào địa chỉ `x2 + 8`.

---

## 6. Nhóm lệnh B-type (Branch) — opcode `1100011`

So sánh 2 thanh ghi, nếu điều kiện đúng thì nhảy tới `pc + imm` (địa chỉ tương đối so với lệnh hiện tại), ngược lại thực hiện `pc + 4` như bình thường. Immediate luôn là **số chẵn** (bit 0 luôn = 0), vì lệnh luôn căn theo 2-byte.

| Lệnh | funct3 | Điều kiện nhảy |
|---|---|---|
| `BEQ`  | 000 | `rs1 == rs2` |
| `BNE`  | 001 | `rs1 != rs2` |
| `BLT`  | 100 | `rs1 < rs2` (so sánh có dấu) |
| `BGE`  | 101 | `rs1 >= rs2` (so sánh có dấu) |
| `BLTU` | 110 | `rs1 < rs2` (so sánh không dấu) |
| `BGEU` | 111 | `rs1 >= rs2` (so sánh không dấu) |

**Cách hiện thực trong ALU**: thường dùng phép SUB (cho BEQ/BNE, kiểm tra qua `zero_flag`) hoặc SLT/SLTU (cho BLT/BGE/BLTU/BGEU, kiểm tra qua kết quả 0/1).

---

## 7. Nhóm lệnh U-type (Upper Immediate)

Dùng để nạp hằng số 20-bit vào 20 bit cao của thanh ghi (12 bit thấp tự động = 0). Thường dùng kết hợp với ADDI để tạo ra hằng số 32-bit đầy đủ (vì I-type ALU chỉ mang được 12-bit).

| Lệnh | Opcode | Hoạt động |
|---|---|---|
| `LUI`   | `0110111` | `rd = imm << 12` (Load Upper Immediate) |
| `AUIPC` | `0010111` | `rd = pc + (imm << 12)` (Add Upper Immediate to PC) |

**Ví dụ nạp hằng số 32-bit đầy đủ** (VD: `0x12345678`):
```
lui  x1, 0x12345        # x1 = 0x12345000
addi x1, x1, 0x678      # x1 = 0x12345678
```

**AUIPC dùng để**: tính địa chỉ tương đối PC-relative cho các chương trình độc lập vị trí (position-independent code), thường đi kèm JALR để nhảy xa hơn tầm của lệnh JAL/Branch thông thường.

---

## 8. Nhóm lệnh J-type (Jump) — opcode `1101111`

### JAL — Jump And Link

```
rd = pc + 4          // lưu địa chỉ quay về
pc = pc + imm         // nhảy tới địa chỉ tương đối (tầm ±1MB)
```

Nếu `rd = x0` thì trở thành lệnh **nhảy không điều kiện** đơn thuần (không cần lưu địa chỉ quay về) — cách RISC-V "tái sử dụng" 1 lệnh cho 2 mục đích (gọi hàm và nhảy vô điều kiện) bằng quy ước `rd`.

---

## 9. Bảng ALU Control tổng hợp (dùng trong thiết kế CPU)

| alu_ctrl | Tên | Phép toán |
|---|---|---|
| `0000` | pass A | `c = a` |
| `0001` | NOT | `c = ~a` |
| `0010` | AND | `c = a & b` |
| `0011` | OR | `c = a \| b` |
| `0100` | XOR | `c = a ^ b` |
| `0101` | ADD | `c = a + b` |
| `0110` | SUB | `c = a - b` |
| `0111` | SLL | `c = a << b[4:0]` |
| `1000` | SRL | `c = a >> b[4:0]` |
| `1001` | SRA | `c = $signed(a) >>> b[4:0]` |
| `1010` | SLT | `c = (signed a < signed b) ? 1 : 0` |
| `1011` | SLTU | `c = (a < b) ? 1 : 0` |

---

## 10. Bảng tín hiệu điều khiển theo opcode (Control Unit)

| opcode | Loại | reg_write | alu_src | mem_read | mem_write | mem_to_reg | branch | jump |
|---|---|---|---|---|---|---|---|---|
| `0110011` (R) | ADD/SUB/... | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `0010011` (I-ALU) | ADDI/... | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `0000011` (I-Load) | LW/LB/... | 1 | 1 | 1 | 0 | 1 | 0 | 0 |
| `0100011` (S) | SW/SB/... | 0 | 1 | 0 | 1 | 0 | 0 | 0 |
| `1100011` (B) | BEQ/BNE/... | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| `1101111` (J) | JAL | 1 | X | 0 | 0 | 0 | 0 | 1 |
| `1100111` (I-Jump) | JALR | 1 | 1 | 0 | 0 | 0 | 0 | 1 |
| `0110111` (U) | LUI | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `0010111` (U) | AUIPC | 1 | X | 0 | 0 | 0 | 0 | 0 |

---


