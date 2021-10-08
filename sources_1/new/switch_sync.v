module switch_sync
(
    input  wire sw_mode_1,
    input  wire sw_mode_2,
    input  wire sw_mode_3A,
    input  wire sw_mode_C,
    input  wire sw_mode_TX,
    input  wire sw_mode_REM,
    output reg[5:0] sw,
    input  wire clk, rst
);

always @(posedge clk, posedge rst)
begin
    if(~rst)
        sw <= 0;
    else
        sw <= {sw_mode_1, sw_mode_2, sw_mode_3A, sw_mode_C, sw_mode_TX, sw_mode_REM};
end

endmodule