module AHB_slave_interface (
    input         hclk,
    input         hresetn,
    input         hwrite,
    input  [1:0]  htrans,
    input         hreadyin,
    input  [31:0] haddr,
    input  [31:0] hwdata,
    output reg        valid,
    output reg        hwrite_reg,
    output reg [31:0] haddr_1,
    output reg [31:0] hwdata_1,
    output reg [2:0]  temp_selx );
always @(*) begin
    valid = hreadyin && htrans[1]; end
always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin haddr_1    <= 0; hwrite_reg <= 0;
    end 
    else if (valid) begin haddr_1    <= haddr; hwrite_reg <= hwrite;
    end end
always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) hwdata_1 <= 0;
    else if (valid) hwdata_1 <= hwdata;
end
always @(*) begin
    case (haddr_1[31:28])
        4'h8: temp_selx = 3'b001;
        4'h9: temp_selx = 3'b010;
        4'hA: temp_selx = 3'b100;
        default: temp_selx = 3'b000; endcase end
endmodule