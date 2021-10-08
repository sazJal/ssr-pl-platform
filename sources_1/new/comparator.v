module comparator
(
    input   wire[15:0] D_1,
    input   wire[15:0] D_2,
    input   wire[15:0] D_3,
    input   wire ADC_clk_in_1,
    input   wire ADC_clk_in_2,
    input   wire ADC_clk_in_3,
    input   wire ADC_OF_1,
    input   wire ADC_OF_2,
    input   wire ADC_OF_3,
    input   wire[15:0]  thrsld,
    output  reg comp_out, 
    output  reg data_out,
    output  wire[15:0] sig_out_D1, 
    output  wire[15:0] sig_out_D2, 
    output  wire[15:0] sig_out_D3, 
    output  wire[15:0] sig_array,
    output  wire[15:0] sig_fltr,
    input   wire clk, rst
);
   
// signal declaration
reg[15:0] comp_min, comp_max;
reg[31:0] under_flow, over_flow;
reg[31:0] sum;
reg[15:0] array[7:0];
reg[15:0] inverted_D1, inverted_D2, inverted_D3;
integer i;

initial
begin
    comp_min  = 45000;
    comp_max  = 32767;
    under_flow = 19'b100_0000_0000_0000_0000;
    over_flow  = 524280;
end
// register
always @ (posedge clk, posedge rst)
if(~rst)
    begin
        for(i=0; i<8; i=i+1)
        begin
            array[i] <= 0;
        end
        sum          <= 0;
        inverted_D1  <= 0;
        inverted_D2  <= 0;
        inverted_D3  <= 0;
        comp_out     <= 1'b0;
        data_out     <= 1'b0;
    end
else
    begin
        for(i = 1; i < 8; i=i+1) 
            begin
                array[i] <= array[i-1];
            end
            
        inverted_D1  = ~D_1 + 1;
        inverted_D2  = ~D_2 + 1;
        inverted_D3  = ~D_3 + 1;

        if(inverted_D1 > comp_max)
            array[0] = 32768 - ((~inverted_D1) + 1);
        else
            array[0] = inverted_D1 + 32768;
            
        sum = sum + array[0] - array[7];
        if(sum >= over_flow)
            sum = over_flow;
                
        data_out = (array[0] > thrsld) ? 1'b1 : 1'b0;            
        comp_out = (array[0] >  comp_min)? 1'b1 : 1'b0;
    end

assign sig_sig_fltr = sum[18:3];
assign sig_out_D1   = inverted_D1;
assign sig_out_D2   = inverted_D2;
assign sig_out_D3   = inverted_D3;
assign sig_array    = array[0];

endmodule