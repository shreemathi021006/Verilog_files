module bridge_wrapper (
    input hclk,
    input hresetn,
    input hwrite,
    input [1:0] htrans,
    input hreadyin,
    input [31:0] haddr,
    input [31:0] hwdata,

    output pwrite,
    output penable,
    output [2:0] psel,
    output [31:0] paddr,
    output [31:0] pwdata,
    output hreadyout
);

bridge uut (
    .hclk(hclk),
    .hresetn(hresetn),
    .hwrite(hwrite),
    .htrans(htrans),
    .hreadyin(hreadyin),
    .haddr(haddr),
    .hwdata(hwdata),
    .pwrite(pwrite),
    .penable(penable),
    .psel(psel),
    .paddr(paddr),
    .pwdata(pwdata),
    .hreadyout(hreadyout)
);

endmodule