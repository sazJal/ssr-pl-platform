module shifter
#(
    M   = 28000, // number of data to be serialized (1.5 ms / 50 ns)  
    N   = 16 // log2(M)
)
(
    input   wire din,
    input   wire from_fifo,
    input   wire start,
    output  reg  dout,
    output  reg  shifted_dout,
    output  wire dout_and,
    output  reg  to_fifo,
    output  wire wr_en,
    output  wire rd_en,
    input   wire  clk, rst
);

localparam[2:0]
    IDLE        = 3'b000,
    START       = 3'b001,
    SERIALIZE   = 3'b010,
    WAIT        = 3'b011,
    DESERIALIZE = 3'b100,
    DONE        = 3'b101;
        
reg[2:0] state_reg, state_next;
reg[N-1:0] s_reg, s_next;
reg wr_en_reg, wr_en_next;
reg rd_en_reg, rd_en_next;

always @(posedge clk, posedge rst)
if(~rst)
    begin
        state_reg   <= IDLE;
        s_reg       <= 0;
        to_fifo     <= 1'b0;
        dout        <= 1'b0;
        shifted_dout  <= 1'b0;
        wr_en_reg   <= 1'b0;
        rd_en_reg   <= 1'b0;
    end
else
    begin
        state_reg   <= state_next;
        s_reg       <= s_next;
        dout        <= din;
        to_fifo     <= din;
        shifted_dout  <= from_fifo;
        wr_en_reg   <= wr_en_next;
        rd_en_reg   <= rd_en_next;
    end

always @(*)
begin
    state_next  = state_reg;
    s_next      = s_reg;
    wr_en_next  = wr_en_reg;
    rd_en_next  = rd_en_reg;
    
    case(state_reg)
        IDLE :
            if(start)
                begin
                    state_next  = START;
                    s_next = 0;
                end                
        START   :
            begin
                wr_en_next  = 1'b1;
                rd_en_next  = 1'b0;
                state_next  = SERIALIZE;                    
                s_next = 0;                
            end
        SERIALIZE :
            begin
                begin
                    wr_en_next = 1'b1;
                    if(s_reg == (M-1))
                        begin
                            wr_en_next  = 1'b0;
                            rd_en_next  = 1'b0;
                            state_next = WAIT;
                            s_next = 0;
                        end
                    else
                        s_next = s_reg + 1;
                end
            end
        WAIT:
            if(start)
                begin
                    wr_en_next  = 1'b0;
                    rd_en_next  = 1'b1;
                    state_next  = DESERIALIZE;                    
                    s_next = 0;           
                end        
        DESERIALIZE :
            begin
                rd_en_next = 1'b1;
                if(s_reg == (M-1))
                    begin
                        rd_en_next = 1'b0;
                        state_next = DONE;
                        s_next = 0;
                    end
                else
                    s_next = s_reg + 1;
            end    
        DONE :
            begin 
                state_next  = IDLE;
            end
    endcase          
end

assign wr_en = wr_en_reg;
assign rd_en = rd_en_reg;
assign state = state_reg;

assign dout_and = dout & shifted_dout;

endmodule