module stc_gen
#(
    K = 20,     // 0.5 ms + 0.25 ms = 0.75 ms (0.25 ms/12.5 us) = 20 
    M = 250,    // (12.5 us / 50 ns ~ 250) creating 12.5 us ticking  
    L = 32      // 0.4 ms / 12.5 us = 32 number of STC decaying gain steps
)
(
    input   wire start,
    input   wire stop,
    output  wire[6:0] D,
    output  reg LE,
    input   wire clk, rst 
);

/* edge detection purpose */
localparam[2:0]
    IDLE        = 3'b000,
    STAGING     = 3'b001,
    WRITE       = 3'b010,
    DONE        = 3'b101;    
    
//initial begin
reg[6:0] att[31:0];

initial 
begin    
    att[0]  = 7'b111_1110;   att[1] = 7'b110_1111;  att[2]  = 7'b110_0010;  att[3]  = 7'b101_0110; 
    att[4]  = 7'b100_1100;   att[5] = 7'b100_0011;  att[6]  = 7'b011_1011;  att[7]  = 7'b011_0100; 
    att[8]  = 7'b010_1110;   att[9] = 7'b010_1000;  att[10] = 7'b010_0011;  att[11] = 7'b001_1111; 
    att[12] = 7'b001_1011;  att[13] = 7'b001_1000;  att[14] = 7'b001_0101;  att[15] = 7'b001_0011; 
    att[16] = 7'b001_0001;  att[17] = 7'b000_1111;  att[18] = 7'b000_1101;  att[19] = 7'b000_1011; 
    att[20] = 7'b000_1010;  att[21] = 7'b000_1001;  att[22] = 7'b000_1000;  att[23] = 7'b000_0111; 
    att[24] = 7'b000_0110;  att[25] = 7'b000_0110;  att[26] = 7'b000_0101;  att[27] = 7'b000_0100; 
    att[28] = 7'b000_0100;  att[29] = 7'b000_0100;  att[30] = 7'b000_0011;  att[31] = 7'b000_0011;
end

// signal declaration
reg[6:0]  d_reg, d_next;
reg[2:0]  state_reg, state_next;
reg[7:0]  s_reg, s_next;
reg[4:0]  t_reg, t_next;
reg[4:0]  a_reg, a_next;



// register
always @ (posedge clk, posedge rst)
if(~rst)
    begin
        state_reg   <= IDLE;
        d_reg       <= 7'b111_1111;
        s_reg       <= 0;
        a_reg       <= 0;
        t_reg       <= 0;
    end
else
    begin
        state_reg   <= state_next;
        d_reg       <= d_next;
        s_reg       <= s_next;
        a_reg       <= a_next;
        t_reg       <= t_next;
    end
       
always @(*)
begin
    state_next  = state_reg;        
    d_next      = d_reg;
    s_next      = s_reg;
    t_next      = t_reg;
    a_next      = a_reg;
    LE          = 1'b1;
    
    case(state_reg)
        IDLE:
            if(start)
                begin
                    state_next = STAGING;
                    s_next = 0;
                    t_next = 0;
                    a_next = 0;
                end
        STAGING :
            if(s_reg == M-1)
                begin
                    s_next = 0;
                    if(t_reg == 7) // 0.1 ms -> 12.5 us * 8
                        begin
                            t_next =  0;
                            state_next = WRITE;
                            d_next = att[a_reg];
                        end
                    else 
                        t_next = t_reg + 1;  
                end
            else
                s_next = s_reg + 1;                                                

        WRITE :
            if(s_reg == M-1)
                begin
                    s_next = 0;
                    if(a_reg == L-1)
                        begin
                            d_next      = 7'b000_0000;
                            state_next  = DONE;
                            a_next      = 0;
                        end  
                    else
                        begin
                            a_next = a_reg + 1;
                            d_next = att[a_reg + 1];
                        end
                    end                        
            else
                s_next = s_reg + 1;          

        DONE:
            if(stop)
                begin
                    state_next = IDLE;
                    d_next = 7'b111_1111;
                end

        default :
            state_next = IDLE;            
    endcase
end

assign D = d_reg;

endmodule