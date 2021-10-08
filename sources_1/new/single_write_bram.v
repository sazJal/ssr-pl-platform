module single_write_bram
(
    input   wire start,
    output  wire[14:0] awaddr,
    output  wire[1:0]  awburst,
    output  wire[7:0]  awlen,
    
    output  wire[2:0]  awsize,
    output  reg awvalid,
    output  wire bready,
    input   wire[31:0] data,
    input   wire[14:0] addr,

    output  wire[31:0] wdata,
    output  reg wlast,
    output  wire[3:0] wstrb,
    output  reg wvalid,

    input   wire aclk, rst
 );

localparam[1:0]
    IDLE        = 2'b00,
    WRITE       = 2'b01,
    LAST        = 2'b10;
    
localparam[1:0]
    zero    = 2'b00,
    edg     = 2'b01,
    one     = 2'b10;    
    
 reg[1:0] state_reg, state_next;
 reg[1:0] level_reg, level_next;
 reg[14:0] awaddr_reg, awaddr_next;
 reg[31:0] wdata_reg, wdata_next;
 reg tick;
 
 always @(posedge aclk, posedge rst)
 begin
    if(~rst)
        begin
            state_reg   <= IDLE;
            awaddr_reg  <= 0;
            wdata_reg   <= 0;
            level_reg   <= zero;
        end
    else
        begin
            state_reg   <= state_next;
            awaddr_reg  <= awaddr_next;
            wdata_reg   <= wdata_next;
            level_reg   <= level_next;
        end
 end

 always @(*)
 begin

    state_next      = state_reg;
    
    awaddr_next     = awaddr_reg;
    awvalid         = 1'b0;

    wdata_next      = wdata_reg;
    wlast           = 1'b0;
    wvalid          = 1'b0;
    
    case (state_reg)
        IDLE    :
        begin
            if(tick)
                begin
                    wdata_next      = data;
                    awaddr_next     = addr;
                    state_next      = WRITE;
                end
        end
        WRITE   :
        begin
            awvalid         = 1'b1;
            wvalid          = 1'b1;
            wlast           = 1'b1;
            state_next      = LAST;
        end
        LAST    :
            begin
                state_next  = IDLE;
            end    
        default :
            state_next      = IDLE;                
    endcase
 end
   
 /* Rising Edge Detection for Sampler */
always @(*)
begin
    level_next  = level_reg;
    tick = 1'b0;
    case(level_reg)
        zero:
            if(start)
                level_next = edg;
        edg:
            begin 
                tick = 1'b1;
                if(start)
                    level_next = one;
                else
                    level_next = zero;
            end    
        one:
            if(~start)
                level_next = zero;
        default: level_next = zero;
    endcase
end
 
 assign awaddr  = awaddr_reg;
 assign awlen   = 0;
 assign awsize  = 2;
 assign awburst = 0; // fixed
 
 assign wdata   = wdata_reg;
 assign wstrb   = 4'hF;
 assign bready  = 1'b1;
 
endmodule