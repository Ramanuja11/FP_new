`timescale 1ns / 1ps

`include "FP_add.v"
`include "fp_mul_270425.v"

module FloatingDivision#(parameter XLEN=32)
                        (input [XLEN-1:0]A,
                         input [XLEN-1:0]B,
                         output zero_division,
                         output [XLEN-1:0] result);

wire [7:0] Exponent;
wire [31:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, result_unprotected;
wire [31:0] reciprocal;
wire [31:0] x0,x1,x2,x3;
wire [5:0] pFlags;
wire [2:0] rnd = 3'b100;

// zero division flag
assign zero_division = (B[30:23] == 0) ? 1'b1 : 1'b0;

/*----Initial value----       B_Mantissa * (2 ^ -1)            32 / 17 */
fp_mul_270425 M1(.a({{1'b0,8'd126,B[22:0]}}),.b(32'h3ff0f0f1),.p(temp1),.pFlags(pFlags),.rnd(rnd)); //verified

//                         48 / 17        -abs(temp1)
fp_add A1(.A(32'h4034b4b5),.B({1'b1,temp1[30:0]}),.result(x0));

/*----First Iteration----*/
fp_mul_270425 M2(.a({{1'b0,8'd126,B[22:0]}}),.b(x0),.p(temp2),.pFlags(pFlags),.rnd(rnd));
//                         +2            -temp2
fp_add A2(.A(32'h40000000),.B({!temp2[31],temp2[30:0]}),.result(temp3));
fp_mul_270425 M3(.a(x0),.b(temp3),.p(x1), .pFlags(pFlags),.rnd(rnd));

/*----Second Iteration----*/
fp_mul_270425 M4(.a({1'b0,8'd126,B[22:0]}),.b(x1),.p(temp4),.pFlags(pFlags),.rnd(rnd));
fp_add A3(.A(32'h40000000),.B({!temp4[31],temp4[30:0]}),.result(temp5));
fp_mul_270425 M5(.a(x1),.b(temp5),.p(x2),.pFlags(pFlags),.rnd(rnd));

/*----Third Iteration----*/
fp_mul_270425 M6(.a({1'b0,8'd126,B[22:0]}),.b(x2),.p(temp6),.pFlags(pFlags),.rnd(rnd));
fp_add A4(.A(32'h40000000),.B({!temp6[31],temp6[30:0]}),.result(temp7));
fp_mul_270425 M7(.a(x2),.b(temp7),.p(x3),.pFlags(pFlags),.rnd(rnd));

/*----Reciprocal : 1/B----*/
assign Exponent = x3[30:23]+8'd126-B[30:23];
assign reciprocal = {B[31],Exponent,x3[22:0]};

/*----Multiplication A*1/B----*/
fp_mul_270425 M8(.a(A), .b(reciprocal), .p(result_unprotected),.pFlags(pFlags),.rnd(rnd));

assign result = ((A[30:23] == 0) || zero_division) ? 32'h0000_0000 : result_unprotected;
endmodule
