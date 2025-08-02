`timescale 1ns / 1ps

`include "FP_compare.v"
module fp_add #(parameter XLEN=32, parameter NSIG=23, parameter NEXP=8)
                        (input [XLEN-1:0]A,
                         input [XLEN-1:0]B,
                         output reg  [XLEN-1:0] result);

reg [XLEN-1:0] A_swap, B_swap;  // comparison-based swap
wire [NSIG:0] A_Mantissa = {1'b1, A_swap[NSIG-1:0]},
        B_Mantissa = {1'b1, B_swap[NSIG-1:0]};
        // stored mantissa is NSIGbit, this is {1'b1, mantissa}
wire [NEXP-1:0] A_Exponent = A_swap[XLEN-2:NSIG], B_Exponent = B_swap[XLEN-2:NSIG];
wire A_sign = A_swap[XLEN-1], B_sign = B_swap[XLEN-1];

reg [NSIG:0] Temp_Mantissa, B_shifted_mantissa;
reg [NSIG-1:0] Mantissa;
reg [NEXP-1:0] Exponent;
reg Sign;

reg [NEXP-1:0] diff_Exponent;
reg [XLEN:0] Temp;
reg carry;
wire comp;

integer i;

// compare absolute values of A, B
fp_compare comp_inst(.A({1'b0, A[XLEN-2:0]}), .B({1'b0, B[XLEN-2:0]}), .result(comp));

always @(*)
begin
// let A >= B (switch A & B based on comp from the FP_compare unit
A_swap = comp ? A : B;
B_swap = comp ? B : A;

// shift B to same exponent (A >= B, exponent diff >= 0)
diff_Exponent = A_Exponent-B_Exponent;
B_shifted_mantissa = (B_Mantissa >> diff_Exponent);

// sum the mantissas (and store potential carry)
{carry,Temp_Mantissa} = (A_sign ~^ B_sign)? A_Mantissa + B_shifted_mantissa : A_Mantissa - B_shifted_mantissa;
Exponent = A_Exponent;

// adjust mantissa to format 1.xxxx (bit 23 is 1)
if(carry)
    begin
        Temp_Mantissa = Temp_Mantissa>>1;
        Exponent = (Exponent < 8'hff) ? Exponent + 1 : 8'hff;  // protect exponent overflow
    end
else if(|Temp_Mantissa != 1'b1)  // mantissa contains no 1 or unknown value (result should be 0)
    begin
        Temp_Mantissa = 0;
    end
else
    begin
        // 1st bit is not 1, but there is some 1 in the mantissa (protecting exponent underflow)
        for(i = 0; Temp_Mantissa[NSIG] !== 1'b1 && Exponent > 0 && i < NSIG+1; i = i + 1) begin
            Temp_Mantissa = Temp_Mantissa << 1;
            Exponent = Exponent - 1;

        end
    end

Sign = A_sign;
Mantissa = Temp_Mantissa[NSIG-1:0];
result = {Sign,Exponent,Mantissa};
end
endmodule
