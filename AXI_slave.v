module AXI4_Lite_Slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,

    // Write Address Channel
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,

    // Write Data Channel
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,

    // Write Response Channel
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,

    // Read Address Channel
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,

    // Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY
);
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    reg axi_awready, axi_wready, axi_bvalid, axi_arready, axi_rvalid;
    reg [1:0] axi_bresp, axi_rresp;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr, axi_araddr;
    reg aw_addr_valid, ar_addr_valid;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // Address Decoding Logic
    function is_addr_valid(input [C_S_AXI_ADDR_WIDTH-1:0] addr);
        is_addr_valid = (addr == 4'h0 || addr == 4'h4 || addr == 4'h8 || addr == 4'hC);
    endfunction

    // Write Channel Logic
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_awready   <= 1'b0;
            axi_wready    <= 1'b0;
            aw_addr_valid <= 1'b0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
                axi_awready   <= 1'b1;
                axi_wready    <= 1'b1;
                axi_awaddr    <= S_AXI_AWADDR;
                aw_addr_valid <= is_addr_valid(S_AXI_AWADDR);
            end else begin
                axi_awready <= 1'b0;
                axi_wready  <= 1'b0;
            end
        end
    end

    // Register Write with Strobe Support
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            slv_reg0 <= 0; slv_reg1 <= 0; slv_reg2 <= 0; slv_reg3 <= 0;
        end else if (axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID && aw_addr_valid) begin
            case (axi_awaddr[3:2])
                2'h0: begin
                    if (S_AXI_WSTRB[0]) slv_reg0[7:0]   <= S_AXI_WDATA[7:0];
                    if (S_AXI_WSTRB[1]) slv_reg0[15:8]  <= S_AXI_WDATA[15:8];
                    if (S_AXI_WSTRB[2]) slv_reg0[23:16] <= S_AXI_WDATA[23:16];
                    if (S_AXI_WSTRB[3]) slv_reg0[31:24] <= S_AXI_WDATA[31:24];
                end
                2'h1: begin
                    if (S_AXI_WSTRB[0]) slv_reg1[7:0]   <= S_AXI_WDATA[7:0];
                    if (S_AXI_WSTRB[1]) slv_reg1[15:8]  <= S_AXI_WDATA[15:8];
                    if (S_AXI_WSTRB[2]) slv_reg1[23:16] <= S_AXI_WDATA[23:16];
                    if (S_AXI_WSTRB[3]) slv_reg1[31:24] <= S_AXI_WDATA[31:24];
                end
                2'h2: begin
                    if (S_AXI_WSTRB[0]) slv_reg2[7:0]   <= S_AXI_WDATA[7:0];
                    if (S_AXI_WSTRB[1]) slv_reg2[15:8]  <= S_AXI_WDATA[15:8];
                    if (S_AXI_WSTRB[2]) slv_reg2[23:16] <= S_AXI_WDATA[23:16];
                    if (S_AXI_WSTRB[3]) slv_reg2[31:24] <= S_AXI_WDATA[31:24];
                end
                2'h3: begin
                    if (S_AXI_WSTRB[0]) slv_reg3[7:0]   <= S_AXI_WDATA[7:0];
                    if (S_AXI_WSTRB[1]) slv_reg3[15:8]  <= S_AXI_WDATA[15:8];
                    if (S_AXI_WSTRB[2]) slv_reg3[23:16] <= S_AXI_WDATA[23:16];
                    if (S_AXI_WSTRB[3]) slv_reg3[31:24] <= S_AXI_WDATA[31:24];
                end
            endcase
        end
    end

    // Write Response
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;
        end else if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && ~axi_bvalid) begin
            axi_bvalid <= 1'b1;
            axi_bresp  <= aw_addr_valid ? 2'b00 : 2'b11; // OKAY or DECERR
        end else if (S_AXI_BREADY && axi_bvalid) begin
            axi_bvalid <= 1'b0;
        end
    end

    // Read Channel Logic
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready   <= 1'b0;
            axi_araddr    <= 0;
            ar_addr_valid <= 1'b0;
        end else if (~axi_arready && S_AXI_ARVALID) begin
            axi_arready   <= 1'b1;
            axi_araddr    <= S_AXI_ARADDR;
            ar_addr_valid <= is_addr_valid(S_AXI_ARADDR);
        end else begin
            axi_arready <= 1'b0;
        end
    end

    // Read Data & Response
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
            axi_rdata  <= 0;
        end else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
            axi_rvalid <= 1'b1;
            axi_rresp  <= ar_addr_valid ? 2'b00 : 2'b11;
            if (ar_addr_valid) begin
                case (axi_araddr[3:2])
                    2'h0: axi_rdata <= slv_reg0;
                    2'h1: axi_rdata <= slv_reg1;
                    2'h2: axi_rdata <= slv_reg2;
                    2'h3: axi_rdata <= slv_reg3;
                endcase
            end else axi_rdata <= 32'hDEADDEAD;
        end else if (axi_rvalid && S_AXI_RREADY) begin
            axi_rvalid <= 1'b0;
        end
    end
endmodule