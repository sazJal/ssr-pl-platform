module led_sync
(
    input wire[7:0] led,
    output wire led_M_1_R,
    output wire led_M_1_G,
    output wire led_M_2_R,
    output wire led_M_2_G,
    output wire led_M_3_R,
    output wire led_M_3_G,
    output wire led_M_C_R,
    output wire led_M_C_G,
    output wire led_Remote_R,
    output wire led_Remote_G,
    output wire led_TX_R,
    output wire led_TX_G,
    output wire led_Fault_R,
    output wire led_Fault_G,
    output wire led_Power_R,
    output wire led_Power_G,
    input  wire clk, rst
);

reg[7:0] led_reg;

always @(posedge clk, posedge rst)
begin
    if(~rst)
        led_reg <= 0;
    else
        led_reg <= led;
end

assign led_Power_G  =  led_reg[0];
assign led_Power_R  = ~led_reg[0];
assign led_Fault_G  =  led_reg[1];
assign led_Fault_R  = ~led_reg[1];
assign led_TX_G     =  led_reg[2];
assign led_TX_R     = ~led_reg[2];
assign led_Remote_G =  led_reg[3];
assign led_Remote_R = ~led_reg[3];
assign led_M_C_G    =  led_reg[4];
assign led_M_C_R    = ~led_reg[4];
assign led_M_3_G    =  led_reg[5];
assign led_M_3_R    = ~led_reg[5];
assign led_M_2_G    =  led_reg[6];
assign led_M_2_R    = ~led_reg[6];
assign led_M_1_G    =  led_reg[7];
assign led_M_1_R    = ~led_reg[7];

endmodule