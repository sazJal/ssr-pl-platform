module dummy_transponder
#(
        L  = 9,  // 0.45 us
        BL = 20, // 1 us
        M  = 450, // maximum length that the detection is considered to be fail (450 x 0.05) = 22.5 us
        S  = 500
    )
   (
        input wire rx, 
        output wire tx,
        output reg done,
        input wire clk, rst
   );
       
   // symbolic state declaration
   localparam [3:0]
      IDLE      = 4'b0000, 
      DETECT_P1 = 4'b0001,
      DELAY1    = 4'b0010,
      DETECT_P3 = 4'b0011,
      START     = 4'b0100,
      DELAY2    = 4'b0101,
      F1        = 4'b0110,
      BLANK     = 4'b0111,
      DATA      = 4'b1000,
      DATX      = 4'b1001,
      F2        = 4'b1010,
      FINISH    = 4'b1011,
      LOOP_DELAY = 4'b1110;
      
   reg[2:0] A,B,C,D;

   // signal declaration
   wire tick;
   reg [3:0] state_reg, state_next;
   reg [5:0] AC_reg, AC_next;
   reg [5:0] BD_reg, BD_next;
   reg tx_reg, tx_next;
   reg [8:0] s_reg, s_next;
   reg [11:0] n_reg, n_next;
   reg[15:0] m_reg, m_next;
   reg[3:0] u_reg, u_next;
   /* set disctance between P2 faliing edge and P3 rising edge */
   initial 
   begin    
        A  = 3'b010;    
        B  = 3'b110;   
        C  = 3'b100;  
        D  = 3'b101;  
    end   
   
   // FSMD state & data registers
   always @(posedge clk, posedge rst)
      if (~rst)
         begin
            state_reg   <= IDLE;
            AC_reg      <= 0;
            BD_reg      <= 0;
            tx_reg      <= 1'b0;
            s_reg       <= 0;
            m_reg       <= 0;
            n_reg       <= 0;
            u_reg       <= 0;
         end
      else
         begin
            state_reg   <= state_next;
            AC_reg      <= AC_next;
            BD_reg      <= BD_next;
            tx_reg      <= tx_next;
            s_reg       <= s_next;
            m_reg       <= m_next;
            n_reg       <= n_next;
            u_reg       <= u_next;
         end
    
   // Frame Detection
   always @*
   begin
      state_next = state_reg;
      AC_next    = AC_reg;
      BD_next    = BD_reg;
      tx_next    = tx_reg;
      s_next     = s_reg;
      n_next     = n_reg;
      m_next     = m_reg;
      u_next     = u_reg;
      done       = 1'b0;
      
      case (state_reg)
         IDLE:
            if (rx) // switch to receive metode detected
               begin
                  state_next = DETECT_P1;
                  s_next = 0;
               end
         DETECT_P1  :
            if(s_reg == 7-1) // (0.7 / (2*0.05)) = 7
                if(rx)
                    begin
                        state_next = DELAY1;
                        s_next   = 0;
                    end
                else
                    state_next = IDLE;    
            else
                s_next = s_reg + 1;
         DELAY1      :
            if(s_reg == 7-1)
                begin
                    state_next = DETECT_P3;
                    s_next = 0;
                end
            else
                s_next = s_reg + 1;      
        DETECT_P3   :
            if(s_reg==M-1)
                begin
                    state_next  = IDLE;                        
                    s_next      = 0;
                end
            else
                if(rx)
                    begin
                        state_next = START;  
                        s_next     = 0;
                    end
                else                        
                    s_next = s_reg + 1;                    
        START       :
            if(s_reg == 7-1) 
                if(rx)
                    begin
                        state_next = DELAY2;
                        s_next = 0;
                    end
                else
                    state_next = IDLE;    
            else
                s_next = s_reg + 1;
         DELAY2         :    
            if(s_reg == 7-1)
                begin
                    tx_next = 1'b1;
                    state_next = F1;
                    AC_next = {C[0], A[0], C[1], A[1], C[2], A[2]};
                    BD_next = {B[0], D[0], B[1], D[1], B[2], D[2]};
                    s_next = 0;
                    n_next = 0;
                end
            else
                s_next = s_reg + 1;      
         F1             :
            if(s_reg == L-1)
                begin
                    state_next = BLANK;
                    tx_next = 1'b0;
                    s_next  = 0;
                end
            else
                s_next = s_reg + 1;            
         BLANK          :
            if(s_reg == BL -1)
                begin
                    s_next = 0;
                    
                    if(n_reg == 7-1)
                        begin
                            tx_next    = 1'b1;
                            state_next = DATX;
                        end
                    else if((n_reg >= 8-1) && (n_reg < 14-1))
                        begin
                            tx_next = BD_reg[5-(n_reg-7)];
                            state_next = DATA;
                        end                            
                    else if(n_reg == 14-1)
                        begin
                            AC_next = 0;
                            BD_next = 0;
                            state_next = F2; 
                            tx_next = 1'b1;
                        end
                    else
                        begin
                            tx_next = AC_reg[5-n_reg];
                            state_next = DATA;                       
                        end
                    n_next = n_reg +1;
                end        
            else
                s_next = s_reg + 1;
         DATA          :  
            if(s_reg == L-1)
                begin
                    tx_next = 1'b0;
                    state_next = BLANK;
                    s_next = 0;
                end
            else
                s_next = s_reg + 1; 
         DATX          :  
            if(s_reg == L-1)
                begin
                    tx_next = 1'b0;
                    state_next = BLANK;
                    s_next = 0;
                end
            else
                s_next = s_reg + 1;                    
        F2             :
            if(s_reg == L-1)
                begin
                    state_next = LOOP_DELAY;
                    tx_next = 1'b0;
                    s_next = 0;
                end
            else
                s_next = s_reg + 1;            
        LOOP_DELAY  :
            if(m_reg == S-1)
                begin
                    m_next = 0;
                    if(u_reg == 16-1)
                        begin
                            state_next = FINISH;
                            u_next = 0;
                        end
                    else
                        begin
                            u_next = u_reg + 1;
                            state_next = DELAY2;
                        end
                end
            else    
                m_next = m_reg + 1;
                
        FINISH         :
            begin
                state_next = IDLE;
                done = 1'b1;
            end      
        default :
            state_next = IDLE;              
      endcase
   end
      
assign tx = tx_reg;

endmodule