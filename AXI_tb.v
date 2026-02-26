`timescale 1ns / 1ps

module tb_axi4_lite_comprehensive();

    // -----------------------------------------------------------
    // 1. SIGNAL DECLARATIONS
    // -----------------------------------------------------------
    reg clk;
    reg resetn;

    reg         usr_write_req;
    reg         usr_read_req;
    reg  [31:0] usr_awaddr;
    reg  [31:0] usr_araddr;
    reg  [31:0] usr_wdata;
    reg  [3:0]  usr_wstrb; 
    
    wire [31:0] usr_rdata;
    wire        usr_wr_busy, usr_wr_done;
    wire [1:0]  usr_wr_resp;
    wire        usr_rd_busy, usr_rd_done;
    wire [1:0]  usr_rd_resp;

    // --- INTERCONNECT SIGNALS ---
    wire [31:0] m_awaddr, s_awaddr, m_wdata, s_wdata, m_araddr, s_araddr, m_rdata, s_rdata;
    wire [2:0]  m_awprot, s_awprot, m_arprot, s_arprot;
    wire [1:0]  m_bresp, s_bresp, m_rresp, s_rresp;
    wire [3:0]  m_wstrb, s_wstrb;
    wire        m_awvalid, s_awvalid, m_awready, s_awready;
    wire        m_wvalid, s_wvalid, m_wready, s_wready;
    wire        m_bvalid, s_bvalid, m_bready, s_bready;
    wire        m_arvalid, s_arvalid, m_arready, s_arready;
    wire        m_rvalid, s_rvalid, m_rready, s_rready;

    reg [31:0] rb;
    integer g;
    integer error_count = 0;
    integer test_count = 0;
    reg [31:0] rand_addr, rand_data;
    reg [3:0]  rand_strb;

    // Fault injection / Delay control flags
    reg delay_awready, delay_wready, delay_bvalid, delay_arready, delay_rvalid;

    // --- SIGNAL MAPPING ---
    assign s_awaddr = m_awaddr;
    assign s_awprot = m_awprot;
    assign s_wdata  = m_wdata;   
    assign s_wstrb  = m_wstrb;
    assign s_araddr = m_araddr;  
    assign s_arprot = m_arprot;
    assign m_bresp  = s_bresp;   
    assign m_rdata  = s_rdata;   
    assign m_rresp  = s_rresp;

    // --- SMART INTERCEPTOR (For Delay & Timeout Testing) ---
    assign s_awvalid = delay_awready ? 1'b0 : m_awvalid;
    assign m_awready = s_awready;
    assign s_wvalid  = delay_wready  ? 1'b0 : m_wvalid;
    assign m_wready  = s_wready;
    assign m_bvalid  = delay_bvalid  ? 1'b0 : s_bvalid; 
    assign s_bready  = delay_bvalid  ? 1'b0 : m_bready; 
    assign s_arvalid = delay_arready ? 1'b0 : m_arvalid;
    assign m_arready = s_arready;
    assign m_rvalid  = delay_rvalid  ? 1'b0 : s_rvalid;
    assign s_rready  = delay_rvalid  ? 1'b0 : m_rready;

    // -----------------------------------------------------------
    // 2. INSTANTIATIONS
    // -----------------------------------------------------------
    AXI4_Lite_Master #(.TIMEOUT_VAL(50)) dut_master (
        .M_AXI_ACLK(clk), .M_AXI_ARESETN(resetn),
        .usr_write_req(usr_write_req), .usr_read_req(usr_read_req),
        .usr_araddr(usr_araddr), .usr_awaddr(usr_awaddr), 
        .usr_wdata(usr_wdata), .usr_wstrb(usr_wstrb), .usr_rdata(usr_rdata),
        .usr_wr_busy(usr_wr_busy), .usr_wr_done(usr_wr_done), .usr_wr_resp(usr_wr_resp),
        .usr_rd_busy(usr_rd_busy), .usr_rd_done(usr_rd_done), .usr_rd_resp(usr_rd_resp),
        .M_AXI_AWADDR(m_awaddr), .M_AXI_AWPROT(m_awprot), .M_AXI_AWVALID(m_awvalid), .M_AXI_AWREADY(m_awready),
        .M_AXI_WDATA(m_wdata), .M_AXI_WSTRB(m_wstrb), .M_AXI_WVALID(m_wvalid), .M_AXI_WREADY(m_wready),
        .M_AXI_BRESP(m_bresp), .M_AXI_BVALID(m_bvalid), .M_AXI_BREADY(m_bready),
        .M_AXI_ARADDR(m_araddr), .M_AXI_ARPROT(m_arprot), .M_AXI_ARVALID(m_arvalid), .M_AXI_ARREADY(m_arready),
        .M_AXI_RDATA(m_rdata), .M_AXI_RRESP(m_rresp), .M_AXI_RVALID(m_rvalid), .M_AXI_RREADY(m_rready)
    );

    AXI4_Lite_Slave #(.C_S_AXI_ADDR_WIDTH(4)) dut_slave (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(resetn),
        .S_AXI_AWADDR(s_awaddr[3:0]), .S_AXI_AWPROT(s_awprot), .S_AXI_AWVALID(s_awvalid), .S_AXI_AWREADY(s_awready),
        .S_AXI_WDATA(s_wdata), .S_AXI_WSTRB(s_wstrb), .S_AXI_WVALID(s_wvalid), .S_AXI_WREADY(s_wready),
        .S_AXI_BRESP(s_bresp), .S_AXI_BVALID(s_bvalid), .S_AXI_BREADY(s_bready),
        .S_AXI_ARADDR(s_araddr[3:0]), .S_AXI_ARPROT(s_arprot), .S_AXI_ARVALID(s_arvalid), .S_AXI_ARREADY(s_arready),
        .S_AXI_RDATA(s_rdata), .S_AXI_RRESP(s_rresp), .S_AXI_RVALID(s_rvalid), .S_AXI_RREADY(s_rready)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // -----------------------------------------------------------
    // 3. HELPER TASKS
    // -----------------------------------------------------------
    task reset_system;
    begin
        resetn = 0; 
        usr_write_req = 0; usr_read_req = 0; usr_wstrb = 4'b1111;
        usr_araddr = 0; usr_awaddr = 0; usr_wdata = 0;
        delay_awready = 0; delay_wready = 0; delay_bvalid = 0;
        delay_arready = 0; delay_rvalid = 0;
        #50; resetn = 1; #20;
    end
    endtask

    task axi_write(input [31:0] waddr, input [31:0] wdata_in, input [3:0] strb);
        integer timeout_cnt;
    begin
        @(posedge clk); 
        usr_awaddr = waddr; usr_wdata = wdata_in; usr_wstrb = strb;
        usr_write_req = 1;
        @(posedge clk); 
        usr_write_req = 0;
        timeout_cnt = 0;
        while (!usr_wr_done && timeout_cnt < 300) begin 
            @(posedge clk); timeout_cnt = timeout_cnt + 1; 
        end
    end
    endtask

    task axi_read(input [31:0] raddr, output [31:0] rdata_out);
        integer timeout_cnt;
    begin
        @(posedge clk); 
        usr_araddr = raddr; usr_read_req = 1;
        @(posedge clk);
        usr_read_req = 0;
        timeout_cnt = 0;
        while (!usr_rd_done && timeout_cnt < 300) begin 
            @(posedge clk); timeout_cnt = timeout_cnt + 1; 
        end
        rdata_out = usr_rdata;
    end
    endtask

    task check_data(input [31:0] exp, input [31:0] act, input [8*40:1] msg);
    begin
        test_count = test_count + 1;
        if (exp !== act) begin
            $display("[%0t] FAIL: %s | Exp: 0x%08h | Act: 0x%08h", $time, msg, exp, act);
            error_count = error_count + 1;
        end else $display("[%0t] PASS: %s", $time, msg);
    end
    endtask

    task check_resp(input [1:0] exp, input [1:0] act, input [8*40:1] msg);
    begin
        test_count = test_count + 1;
        if (exp !== act) begin
            $display("[%0t] FAIL: %s | Exp Resp: %b | Act Resp: %b", $time, msg, exp, act);
            error_count = error_count + 1;
        end else $display("[%0t] PASS: %s (Resp = %b)", $time, msg, act);
    end
    endtask

    // -----------------------------------------------------------
    // 4. MAIN TEST SEQUENCE
    // -----------------------------------------------------------
    initial begin
        reset_system();

        $display("\n[PHASE 1] INITIALIZATION & BASIC ACCESS");
        axi_write(32'h00, 32'h11223344, 4'b1111); check_resp(2'b00, usr_wr_resp, "Write 0x00 OKAY");
        axi_read (32'h00, rb); check_data(32'h11223344, rb, "Read 0x00");

        $display("\n[PHASE 2] SCAN VALID SLAVE ADDRESSES");
        for (g = 0; g < 4; g = g + 1) begin
            axi_write(g*4, 32'hA5A5_5A5A + g, 4'b1111);
            axi_read (g*4, rb); check_data(32'hA5A5_5A5A + g, rb, "Valid Address Check");
        end

        $display("\n[PHASE 3] WSTRB BRANCH COVERAGE");
        for (g = 0; g < 16; g = g + 1) begin
            axi_write(32'h04, 32'h0000_0000, 4'b1111);
            axi_write(32'h04, 32'hFFFF_FFFF, g[3:0]);  
            axi_read (32'h04, rb);
        end

        $display("\n[PHASE 4] WRITE DECERR (INVALID ADDR)");
        axi_write(32'h05, 32'hDEADBEEF, 4'b1111);
        check_resp(2'b11, usr_wr_resp, "DECERR caught on invalid write");

        $display("\n[PHASE 5] READ DECERR (INVALID ADDR)");
        axi_read(32'h06, rb);
        check_resp(2'b11, usr_rd_resp, "DECERR caught on invalid read");
        check_data(32'hDEADDEAD, rb, "Dummy data received correctly");

        $display("\n[PHASE 6] FEC: DELAYED AWREADY");
        delay_awready = 1;
        fork
            axi_write(32'h08, 32'h11111111, 4'b1111);
            begin repeat(10) @(posedge clk); delay_awready = 0; end
        join
        check_resp(2'b00, usr_wr_resp, "AWREADY recovery OK");

        $display("\n[PHASE 7] FEC: DELAYED WREADY");
        delay_wready = 1;
        fork
            axi_write(32'h08, 32'h22222222, 4'b1111);
            begin repeat(10) @(posedge clk); delay_wready = 0; end
        join
        check_resp(2'b00, usr_wr_resp, "WREADY recovery OK");

        $display("\n[PHASE 8] FEC: DELAYED BVALID");
        delay_bvalid = 1;
        fork
            axi_write(32'h08, 32'h33333333, 4'b1111);
            begin repeat(10) @(posedge clk); delay_bvalid = 0; end
        join
        check_resp(2'b00, usr_wr_resp, "BVALID recovery OK");

        $display("\n[PHASE 9] FEC: DELAYED ARREADY");
        delay_arready = 1;
        fork
            axi_read(32'h08, rb);
            begin repeat(10) @(posedge clk); delay_arready = 0; end
        join
        check_resp(2'b00, usr_rd_resp, "ARREADY recovery OK");

        $display("\n[PHASE 10] FEC: DELAYED RVALID");
        delay_rvalid = 1;
        fork
            axi_read(32'h08, rb);
            begin repeat(10) @(posedge clk); delay_rvalid = 0; end
        join
        check_resp(2'b00, usr_rd_resp, "RVALID recovery OK");

        $display("\n[PHASE 11] TIMEOUT WRITE: AW/W CHANNEL");
        delay_awready = 1; delay_wready = 1;
        axi_write(32'h00, 32'h99999999, 4'b1111);
        check_resp(2'b10, usr_wr_resp, "Timeout caught on AW/W");
        delay_awready = 0; delay_wready = 0; reset_system();

        $display("\n[PHASE 12] TIMEOUT WRITE: B CHANNEL");
        delay_bvalid = 1;
        axi_write(32'h00, 32'h88888888, 4'b1111);
        check_resp(2'b10, usr_wr_resp, "Timeout caught on B channel");
        delay_bvalid = 0; reset_system();

        $display("\n[PHASE 13] TIMEOUT READ: AR CHANNEL");
        delay_arready = 1;
        axi_read(32'h04, rb);
        check_resp(2'b10, usr_rd_resp, "Timeout caught on AR channel");
        delay_arready = 0; reset_system();

        $display("\n[PHASE 14] TIMEOUT READ: R CHANNEL");
        delay_rvalid = 1;
        axi_read(32'h08, rb);
        check_resp(2'b10, usr_rd_resp, "Timeout caught on R channel");
        delay_rvalid = 0; reset_system();

        $display("\n[PHASE 15] TOGGLE COVERAGE: DATA BUS");
        for (g = 0; g < 32; g = g + 1) begin
            axi_write(32'h00, 32'b1 << g, 4'b1111);
            axi_write(32'h04, ~(32'b1 << g), 4'b1111);
        end

        $display("\n[PHASE 16] TOGGLE COVERAGE: ADDRESS BUS");
        for (g = 0; g < 32; g = g + 1) begin
            axi_write((32'b1 << g), 32'h1234, 4'b1111);
            axi_read((~(32'b1 << g)), rb);
        end

        $display("\n[PHASE 17] SIMULTANEOUS R/W CONFLICT");
        reset_system();
        fork
            axi_write(32'h0C, 32'hABCD_EF01, 4'b1111);
            axi_read (32'h08, rb);
        join
        axi_read(32'h0C, rb); check_data(32'hABCD_EF01, rb, "Conflict test passed");

        $display("\n[PHASE 18] CONSTRAINED RANDOM STRESS");
        for (g = 0; g < 500; g = g + 1) begin
            rand_addr = ($random & 32'h0000_000C);
            rand_data = $random;
            rand_strb = $random;
            fork axi_write(rand_addr, rand_data, rand_strb); join
            axi_read(rand_addr, rb);
        end

        $display("\n==================================================");
        $display("   FINAL TEST REPORT");
        $display("   Total Tests: %0d | Errors: %0d", test_count, error_count);
        $display("   RESULT: %s", (error_count == 0) ? "SUCCESS" : "FAILED");
        $display("==================================================\n");

        $finish;
    end
endmodule