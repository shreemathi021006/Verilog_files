module bridge (
    input hclk,
    input hresetn,
    // AHB SIDE
    input hwrite,
    input [1:0] htrans,
    input hreadyin,
    input [31:0] haddr,
    input [31:0] hwdata,
    // APB OUTPUTS
    output pwrite,
    output penable,
    output [2:0] psel,
    output [31:0] paddr,
    output [31:0] pwdata,
    output hreadyout
);
wire valid;
wire hwrite_reg;
wire [31:0] haddr_1;
wire [31:0] hwdata_1;
wire [2:0] temp_selx;
AHB_slave_interface ahb_if (
    .hclk(hclk),
    .hresetn(hresetn),
    .hwrite(hwrite),
    .htrans(htrans),
    .hreadyin(hreadyin),
    .haddr(haddr),
    .hwdata(hwdata),

    .valid(valid),
    .hwrite_reg(hwrite_reg),
    .haddr_1(haddr_1),
    .hwdata_1(hwdata_1),
    .temp_selx(temp_selx)
);
APB_controller apb_ctrl (
    .hclk(hclk),
    .hresetn(hresetn),
    .valid(valid),
    .hwrite_reg(hwrite_reg),
    .haddr_1(haddr_1),
    .hwdata_1(hwdata_1),
    .temp_selx(temp_selx),

    .pwrite(pwrite),
    .penable(penable),
    .psel(psel),
    .paddr(paddr),
    .pwdata(pwdata),
    .hreadyout(hreadyout)
);
endmodule