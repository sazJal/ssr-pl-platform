module delay_line
#(
    N = 100 
)
(
    input   wire d,
    output  reg q,
    input   wire clk, rst
);

reg[N-1:0] delay;

always @ (posedge clk, posedge rst)
    if(~rst)
        begin
            q <= 1'b0;
        end        
    else
        begin
            delay    <= delay << 1;
            delay[0] <= d;
            q        <= delay[N-1];
        end      

endmodule