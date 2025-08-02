`timescale 1ns / 1ps

`ifndef _floating_compare
`define _floating_compare

// returns A >= B via the output register
parameter XLEN = 32;
parameter NSIG = 23;
parameter NEXP = 8;  // 32 bit definitiont 

module fp_compare (input [XLEN-1:0]A,
                   input [XLEN-1:0]B,
                   output reg result);

    always @(*) begin
        // compare signs
        if (A[XLEN-1] != B[XLEN-1])
            result = ~A[XLEN-1];  // A is positive (0) -> A >= B -> result = 1

        // compare exponents
        else begin
            if (A[XLEN-2:NSIG] != B[XLEN-2:NSIG]) begin
                result = (A[XLEN-2:NSIG] > B[XLEN-2:NSIG]) ? 1'b1 : 1'b0;
                // A has bigger exponent than B, so it is bigger
if (A[XLEN-1]) result = ~result;
                // but if A is negative (1), bigger exponent means smaller number
            end
            // compare mantissas
            else begin
                result = (A[NSIG-1:0] > B[NSIG-1:0]) ? 1'b1 : 1'b0;
                // A has bigger mantissa than B, so it is bigger
                if (A[XLEN-1]) result = ~result;
                // but if A is negative (1), bigger mantissa means smaller number
            end
        end
    end

endmodule
`endif //_floating_compare
