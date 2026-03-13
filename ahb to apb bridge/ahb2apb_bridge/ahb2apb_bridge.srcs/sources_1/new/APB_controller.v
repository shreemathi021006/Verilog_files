module APB_controller (
    input hclk,
    input hresetn,
    input valid,
    input hwrite_reg,
    input [31:0] haddr_1,
    input [31:0] hwdata_1,
    input [2:0] temp_selx,

    output reg pwrite,
    output reg penable,
    output reg [2:0] psel,
    output reg [31:0] paddr,
    output reg [31:0] pwdata,
    output reg hreadyout
);

reg [1:0] state, next_state;

parameter IDLE   = 2'b00,
          SETUP  = 2'b01,
          ENABLE = 2'b10;

//////////////////////////////////////////////////////
// STATE REGISTER
//////////////////////////////////////////////////////

always @(posedge hclk or negedge hresetn) begin
    if (!hresetn)
        state <= IDLE;
    else
        state <= next_state;
end

//////////////////////////////////////////////////////
// NEXT STATE LOGIC
//////////////////////////////////////////////////////

always @(*) begin
    case (state)
        IDLE:   next_state = (valid) ? SETUP : IDLE;
        SETUP:  next_state = ENABLE;
        ENABLE: next_state = (valid) ? SETUP : IDLE;
        default: next_state = IDLE;
    endcase
end

//////////////////////////////////////////////////////
// OUTPUT LOGIC
//////////////////////////////////////////////////////

always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
        pwrite    <= 0;
        penable   <= 0;
        psel      <= 0;
        paddr     <= 0;
        pwdata    <= 0;
        hreadyout <= 1;
    end 
    else begin
        case (state)

            IDLE: begin
                psel      <= 0;
                penable   <= 0;
                pwrite    <= 0;
                hreadyout <= 1;
            end

            SETUP: begin
                psel      <= temp_selx;
                paddr     <= haddr_1;
                pwdata    <= hwdata_1;
                pwrite    <= hwrite_reg;
                penable   <= 0;
                hreadyout <= 0;
            end

            ENABLE: begin
                psel      <= temp_selx;
                paddr     <= haddr_1;
                pwdata    <= hwdata_1;
                pwrite    <= hwrite_reg;
                penable   <= 1;
                hreadyout <= 1;
            end

        endcase
    end
end

endmodule