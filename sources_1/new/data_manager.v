module data_manager
(
    input   wire[3:0]   mode,
    input   wire[2:0]   A, B, C, D,
    input   wire[19:0]  rg,
    input   wire[16:0]  orientation, 
    input   wire rx_sync,
    input   wire valid,
    output  reg  start,
    output  wire[31:0] data,
    output  wire[14:0] address,
    output  reg  trigger,
    input   wire aclk,
    input   wire rst 
);

localparam[2:0]
    IDLE        = 3'b000,
    DELAY       = 3'b001,
    ID          = 3'b010,
    SUMMARY     = 3'b011,
    DATA        = 3'b100,
    FINISH      = 3'b101;
    
localparam[1:0]
    ZERO    = 2'b00,
    EDG     = 2'b01,
    ONE     = 2'b10;    

reg[1:0] level_reg, level_next;
reg[3:0] s_reg, s_next;
reg[7:0] num_reg, num_next;
reg[31:0] data_reg, data_next;
reg[14:0] addr_reg, addr_next;
reg[2:0] state_reg, state_next;
reg sample_tick;

always @ (posedge aclk, posedge rst)
    if(~rst)
        begin
            level_reg   <= ZERO;
            state_reg   <= IDLE;
            addr_reg    <= 0;
            data_reg    <= 0;
            num_reg     <= 0;
            s_reg       <= 0;
        end        
    else
        begin
            level_reg   <= level_next;
            state_reg   <= state_next;
            addr_reg    <= addr_next;
            data_reg    <= data_next;
            num_reg     <= num_next;
            s_reg       <= s_next;
        end
          
always @(*)
    begin
        state_next  = state_reg;
        data_next   = data_reg;
        addr_next   = addr_reg;
        s_next      = s_reg;
        num_next    = num_reg;
        start       = 1'b0;
        trigger     = 1'b0;
        
        case (state_reg)
            IDLE    :
                if(rx_sync)
                    begin
                        state_next  = ID;
                        data_next   = 32'hC623_0121;
                        addr_next   = 0;
                        num_next    = 0;
                        s_next      = 0;
                    end
            ID      :
                begin
                    start = 1'b1;
                    if (s_reg == 4-1)
                        begin
                            state_next  = DATA;
                            addr_next   = addr_reg + 12;
                            s_next      = 0;
                        end
                    else
                        s_next = s_reg + 1;                   
                end  
            DATA    :
                begin
                    if(sample_tick)
                        begin 
                            data_next   = {A, B, C, D, rg};                
                            addr_next   = addr_reg + 4;
                            num_next    = num_reg + 1;
                            state_next  = DELAY;
                        end    
                    
                    if(!rx_sync)  
                        begin
                            data_next   = {num_reg, 3'b0000, mode, orientation};                
                            addr_next   = 4;
                            state_next  = DELAY;
                        end                        
                end
            DELAY  :
                begin
                    start = 1'b1;
                    if (s_reg == 4-1)
                        begin
                            s_next      = 0;
                            if(rx_sync)
                                state_next  = DATA;
                            else
                                state_next  = FINISH;    
                        end 
                    else
                        s_next = s_reg + 1;                   
                end
            FINISH  :
                begin
                    trigger     = 1'b1;
                    if(s_reg == 10-1)
                        state_next = IDLE;
                    else
                        s_next = s_reg + 1;                
                end
        endcase
    end            
    
/* Falling Edge Detection for Sampler */
always @(*)
begin
    level_next  = level_reg;
    sample_tick = 1'b0;
    case(level_reg)
        ZERO:
            if(valid)
                level_next = EDG;
        EDG:
            begin
                sample_tick = 1'b1;
                if(~valid)
                    level_next = ZERO;
                else
                    level_next = ONE;
            end    
        ONE:
            if(~valid)
                level_next = ZERO;
        default: level_next = ZERO;
    endcase
end 
   
assign data     = data_reg;
assign address  = addr_reg;

endmodule