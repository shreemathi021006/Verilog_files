module tb;
reg hclk, hresetn;
reg hwrite;
reg [1:0] htrans;
reg hreadyin;
reg [31:0] haddr;
reg [31:0] hwdata;
wire pwrite, penable;
wire [2:0] psel;
wire [31:0] paddr;
wire [31:0] pwdata;
wire hreadyout;
bridge dut (
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
always #5 hclk = ~hclk;   // 10 time unit clock
task reset;
begin
    hresetn = 0;
    #10;
    hresetn = 1;
end
endtask
task single_write;
begin
    @(posedge hclk);
    hwrite   = 1;
    htrans   = 2'b10;   // NONSEQ
    hreadyin = 1;
    haddr    = 32'h8000_0000;
    hwdata   = 32'h12345678;
    @(posedge hclk);
    htrans = 2'b00;     // IDLE
end
endtask
task single_read;
begin
    @(posedge hclk);
    hwrite   = 0;
    htrans   = 2'b10;
    hreadyin = 1;
    haddr    = 32'h8000_0000;

    @(posedge hclk);
    htrans = 2'b00;
end
endtask
integer i;
task burst_write;
begin
    @(posedge hclk);
    hwrite   = 1;
    htrans   = 2'b10;
    hreadyin = 1;
    haddr    = 32'h8000_0000;

    for (i = 0; i < 4; i = i + 1) begin
        @(posedge hclk);
        htrans = 2'b11;     // SEQ
        haddr  = haddr + 4;
        hwdata = $random;
    end

    @(posedge hclk);
    htrans = 2'b00;
end
endtask
initial begin
    // Initialize
    hclk = 0;
    hwrite = 0;
    htrans = 0;
    hreadyin = 0;
    haddr = 0;
    hwdata = 0;
    reset;
    #10 single_write;
    #20 burst_write;
    #20 single_read;
    #50 $finish;
end
endmodule