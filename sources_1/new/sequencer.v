module sequencer
#(
    M   = 30000,    // 1.5 ms / 50 ns = 60000
    L   = 2         // interlace
)
(
    input  wire[3:0]    selector,
    input  wire         tx_on,
    output wire[3:0]    mode,
    output wire         oddeven,
    output wire         stop,
    input  wire         clk, rst
);

localparam[1:0]
    IDLE            = 2'b00,
    RUNNING         = 2'b01,
    TESTING         = 2'b10, // not used
    FINISH          = 2'b11;
    
reg stop_tick;
reg[1:0] state_reg, state_next;
reg[3:0] mode_reg, mode_next;
reg[18:0]   r_reg, r_next;     // signal timer
reg[1:0]    s_reg, s_next;     // number of interlace
reg[2:0]    n_reg, n_next;     // number of mode being used in one sequence
reg[2:0] sel_reg, sel_next;
    
always @ (posedge clk, posedge rst)
    if(~rst)
        begin
            r_reg       <= 0;
            s_reg       <= 0;
            n_reg       <= 0;
            state_reg   <= IDLE;
            mode_reg    <= 0;
            sel_reg     <= 0;
        end        
    else
        begin
            r_reg       <= r_next;
            s_reg       <= s_next;
            n_reg       <= n_next;
            state_reg   <= state_next;
            mode_reg    <= mode_next;
            sel_reg     <= sel_next;
        end

always @(*)
begin
    state_next  = state_reg;
    mode_next   = mode_reg;
    sel_next    = sel_reg;
    r_next      = r_reg;
    s_next      = s_reg;
    n_next      = n_reg;
    stop_tick   = 1'b0;

    case(state_reg)
        IDLE:
            if(tx_on)
                begin
                    r_next = 0;
                    s_next = 0;
                    n_next = {2'b00,selector[3]} + {2'b00, selector[2]} + {2'b00, selector[1]} + {2'b00, selector[0]};
                    
                    if(selector[0]) 
                        begin
                            state_next = RUNNING;    
                            sel_next   = {selector[3:1]}; // next mode : 2
                            mode_next  = 4'b0001;         // current mode : 1           
                        end
                    else if (selector[1] && !selector[0])
                        begin
                            state_next = RUNNING;    
                            sel_next   = {1'b0, selector[3:2]}; // next mode : 3A
                            mode_next  = 4'b0010;               // current mode : 2
                        end    
                    else if (selector[2] && !selector[1] && !selector[0])
                        begin
                            state_next = RUNNING;
                            sel_next   = {2'b00, selector[3]}; // next mode : C
                            mode_next  = 4'b0100;              // current mode : 3A 
                        end
                    else if (selector[3] && !selector[2] && !selector[1] && !selector[0])
                        begin
                            state_next = RUNNING;
                            sel_next   = 3'b000;   // no next mode 
                            mode_next  = 4'b1000;  // current mode : C
                        end      
                end
        RUNNING:
            if(r_reg == M-1)    /* check if the counting reaches 1.5 ms */
                begin
                    r_next = 0;
                    stop_tick = 1'b1;
                    if(s_reg == L-1) /* check if the counting reaches number of interlacing */
                        begin
                            s_next = 0;
                            if(n_reg == 1)  /* all modes all aready processed */
                                begin
                                    mode_next = 4'b0000;
                                    state_next = FINISH;
                                end    
                            else
                                begin
                                    n_next = n_reg - 1;                 
                                    /* check for any consecutive mode */                      
                                    if(sel_reg[0])  
                                        begin
                                            sel_next = {1'b0, sel_reg[2:1]};   
                                            mode_next = {mode_reg[2:0], 1'b0};
                                        end
                                    else if(sel_reg[1] && !sel_reg[0]) 
                                        begin
                                            sel_next = {2'b00, sel_reg[2]};  
                                            mode_next = {mode_reg[1:0], 2'b00};
                                        end                            
                                    else if(sel_reg[2] && !sel_reg[1] && !sel_reg[0]) 
                                        begin
                                           /* this part supposed to be finished */
                                            mode_next = {mode_reg[0], 3'b000};
                                        end 
                                end
                         end
                    else
                        begin
                            s_next      = s_reg + 1;
                        end                        
                end            
            else
                r_next = r_reg + 1;
        FINISH:
            begin
                state_next = IDLE;
            end
        default:
            state_next = IDLE;        
    endcase
end

assign oddeven  = s_reg[0];
assign mode     = mode_reg;
assign stop     = stop_tick;

endmodule