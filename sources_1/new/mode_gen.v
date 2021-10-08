module mode_gen
#(
    L = 46     // ((3 us - 0.7 us) / 0.05 ns = 46
)
(
    output wire      P,
    output wire      MO,
    output reg       start_STC,
    output reg       start_shift,
    output reg       rx_sync,
    input  wire[3:0] mode, 
    input  wire      oddeven,
    input  wire      stop,
    input  wire      no_P2,
    input  wire      clk, rst
);
  
localparam [3:0]
    IDLE        = 4'b0000,
    START       = 4'b0001,
    P1          = 4'b0010,
    BLANK1      = 4'b0011,
    P2          = 4'b0100,
    NO_P2       = 4'b0101,
    BLANK2      = 4'b0110,
    P3          = 4'b0111,
    WAIT_CT     = 4'b1000,
    ENABLE_CT   = 4'b1001,
    FINISH      = 4'b1010;

reg[8:0] th[3:0];
    
/* set distance between P2 faliing edge and P3 rising edge */
initial 
begin    
    th[0]  = 9'b0_0000_0100;  // set 4   -> 2.8 us + (4 x 0.05 us)     = 3 us  
    th[1]  = 9'b0_0010_1100;  // set 44  -> 2.8 us + (44 x 0.05 us)    = 5 us 
    th[2]  = 9'b0_0110_1000;  // set 104 -> 2.8 us + (104 x 0.05 us)   = 8 us
    th[3]  = 9'b1_0110_1100;  // set 364 -> 2.8 us + (364 x 0.05 us)   = 21 us
end
    
// signal declaration
reg[3:0] state_reg, state_next;
reg[8:0] s_reg, s_next;
reg[7:0] comp;
reg[1:0] level_reg, level_next;
reg[1:0] index;
reg p_reg, p_next;
reg MO_reg, MO_next;
reg tick;

// FSMD state & data registers
always @(posedge clk, posedge rst)
if(~rst)
    begin
        state_reg   <= IDLE;
        s_reg       <= 0;
        p_reg       <= 1'b0;
        MO_reg      <= 1'b0;
//        level_reg   <= ONE; 
    end
else
    begin
        state_reg   <= state_next;
        s_reg       <= s_next;
        p_reg       <= p_next;
        MO_reg      <= MO_next;
//        level_reg   <= level_next;
    end
    
  
 always @*
 begin
    state_next  = state_reg;
    s_next      = s_reg;
    p_next      = p_reg;
    MO_next     = MO_reg;
    start_STC   = 1'b0;
    start_shift = 1'b0;
    rx_sync     = 1'b0;
    
    case(state_reg)
        IDLE:
            begin
                p_next      = 1'b0;
                MO_next     = 1'b0;
                if((mode[0] == 1'b1) || (mode[1] == 1'b1) || (mode[2] == 1'b1) || (mode[3] == 1'b1))
                    begin
                        start_shift     = 1'b1;
                        state_next      = P1;
                        s_next = 0;
                    end
            end
        P1:
            begin
                p_next      = 1'b1;
                MO_next     = 1'b0;
                if(s_reg==14-1)   // 0.7 us ( 0.05 us x 14)
                    begin
                        state_next = BLANK1;
                        s_next = 0;
                    end
                else
                    s_next = s_reg + 1;
            end
        BLANK1:
            begin
                p_next      = 1'b0;
                MO_next     = 1'b1;
//                    if(s_reg==24-1) // 1.2 us (2-0.8) us
                if(s_reg==26-1) // 1.3 us (2-0.7) us
                    begin
                        s_next = 0;                            
                        if(no_P2)
                            state_next = NO_P2;
                        else
                            state_next = P2;    
                    end
                else
                    s_next = s_reg + 1;
            end
        P2:
            begin
                p_next      = 1'b1;
                MO_next     = 1'b1;
                if(s_reg==16-1) // 0.8 us
                    begin
                        state_next = BLANK2;
                        case(mode)
                            4'b0001 : index = 0;
                            4'b0010 : index = 1;
                            4'b0100 : index = 2;
                            4'b1000 : index = 3;                        
                        endcase
                        s_next = 0;
                    end
                else
                    s_next = s_reg + 1;
            end
        NO_P2:
            begin
                p_next      = 1'b0;
                MO_next     = 1'b1;
                if(s_reg==16-1) // 0.8 us
                    begin
                        state_next = BLANK2;
                        case(mode)
                            4'b0001 : index = 0;
                            4'b0010 : index = 1;
                            4'b0100 : index = 2;
                            4'b1000 : index = 3;                        
                        endcase
                        s_next = 0;
                    end
                else
                    s_next = s_reg + 1;
        end    
        BLANK2:
            begin
                p_next      = 1'b0;
                MO_next     = 1'b0;
//                    if(s_reg == 4-2) // distnce between P2 and P3 
                if(s_reg == th[index]-1) // distnce between P2 and P3 
                    begin
                        s_next = 0;
                        state_next = P3;
                    end
                else
                    s_next = s_reg + 1;
            end
        P3 :
            begin
                p_next      = 1'b1;
                MO_next     = 1'b0;
                if(s_reg==14-1) // 0.7 us
                    begin
                        state_next = WAIT_CT;
                        s_next = 0;
                    end
                else
                    s_next = s_reg + 1;
            end
        WAIT_CT:     // generate signal to start range counting and STC
            begin
                p_next      = 1'b0;
                MO_next     = 1'b0; 
                if(s_reg==L-1) 
                    begin
                        state_next = ENABLE_CT;
                        s_next = 0;
                    end
                else
                    s_next = s_reg + 1;
            end
        ENABLE_CT :
            begin    
               p_next       = 1'b0;
               MO_next      = 1'b0;
               start_STC    = 1'b1;
               state_next  = FINISH;
            end   
        FINISH:
            begin
                if(oddeven)
                    rx_sync     = 1'b1;
                p_next      = 1'b0;
                MO_next     = 1'b0;
                if(stop) 
                    begin
                        state_next = IDLE;
                    end                    
            end  
        default :
            state_next = IDLE;                                  
    endcase
 end
 
assign P            = p_reg;
assign MO           = MO_reg;

endmodule