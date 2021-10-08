module noise_floor_power
#(
    N = 16 // number in delay    
)
(
    input   wire[15:0] D,
    output  wire[15:0] threshold, 
    input   wire clk, rst
);
   
// signal declaration
reg[15:0] comp_max;
reg[31:0] over_flow;
reg[31:0] sum;
reg[15:0] array[N-1:0];
reg[15:0] inverted_D;
integer i;

initial
begin
    comp_max    = 32767;
    over_flow   = 1048560; // 65535 * 16
end
// register
always @ (posedge clk, posedge rst)
if(~rst)
    begin
        for(i=0; i<N; i=i+1)
        begin
            array[i] <= 0;
        end
        sum          <= 0;
        inverted_D  <= 0;
    end
else
    begin
        for(i = 1; i <N; i=i+1) 
            begin
                array[i] <= array[i-1];
            end
            
        inverted_D  = ~D + 1;
        
        if(inverted_D > comp_max)
            array[0] = 32768 - ((~inverted_D) + 1);
        else
            array[0] = inverted_D + 32768;

        sum = sum + array[0] - array[N-1];
        if(sum >= over_flow)
            sum = over_flow;
    end

assign threshold    = sum[19:4];

endmodule