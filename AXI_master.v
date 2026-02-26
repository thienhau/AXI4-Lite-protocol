module AXI4_Lite_Master #(
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
    parameter integer C_M_AXI_DATA_WIDTH = 32,
    parameter integer TIMEOUT_VAL = 255 
) (
    input wire  M_AXI_ACLK,
    input wire  M_AXI_ARESETN,

    // User Interface
    input wire  usr_write_req,
    input wire  usr_read_req,
    input wire  [C_M_AXI_ADDR_WIDTH-1:0] usr_araddr, usr_awaddr,
    input wire  [C_M_AXI_DATA_WIDTH-1:0] usr_wdata,
    input wire  [C_M_AXI_DATA_WIDTH/8-1:0] usr_wstrb,
    output reg  [C_M_AXI_DATA_WIDTH-1:0] usr_rdata,

    output wire usr_wr_busy, usr_wr_done,
    output wire [1:0] usr_wr_resp,
    output wire usr_rd_busy, usr_rd_done,
    output wire [1:0] usr_rd_resp,

    // AXI4-Lite Interface
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [2 : 0] M_AXI_AWPROT,
    output wire  M_AXI_AWVALID,
    input wire  M_AXI_AWREADY,

    output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
    output wire  M_AXI_WVALID,
    input wire  M_AXI_WREADY,

    input wire [1 : 0] M_AXI_BRESP,
    input wire  M_AXI_BVALID,
    output wire  M_AXI_BREADY,

    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [2 : 0] M_AXI_ARPROT,
    output wire  M_AXI_ARVALID,
    input wire  M_AXI_ARREADY,

    input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0] M_AXI_RRESP,
    input wire  M_AXI_RVALID,
    output wire  M_AXI_RREADY
);

    // FSM States
    localparam W_IDLE = 2'b00, W_AW_W = 2'b01, W_B = 2'b10;
    localparam R_IDLE = 2'b00, R_AR   = 2'b01, R_R = 2'b10;

    reg [1:0] w_state, r_state;
    reg [C_M_AXI_ADDR_WIDTH-1:0] axi_awaddr, axi_araddr;
    reg [C_M_AXI_DATA_WIDTH-1:0] axi_wdata;
    reg axi_awvalid, axi_wvalid, axi_bready;
    reg axi_arvalid, axi_rready;
    reg wr_busy, wr_done, rd_busy, rd_done;
    reg [1:0] wr_resp, rd_resp;
    reg [7:0] w_timeout_cnt, r_timeout_cnt;

    assign M_AXI_AWADDR  = axi_awaddr;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_AWVALID = axi_awvalid;
    assign M_AXI_WDATA   = axi_wdata;
    assign M_AXI_WSTRB   = usr_wstrb;
    assign M_AXI_WVALID  = axi_wvalid;
    assign M_AXI_BREADY  = axi_bready;
    assign M_AXI_ARADDR  = axi_araddr;
    assign M_AXI_ARPROT  = 3'b000;
    assign M_AXI_ARVALID = axi_arvalid;
    assign M_AXI_RREADY  = axi_rready;

    assign usr_wr_busy = wr_busy;  
    assign usr_wr_done = wr_done;  
    assign usr_wr_resp = wr_resp;
    assign usr_rd_busy = rd_busy;  
    assign usr_rd_done = rd_done;
    assign usr_rd_resp = rd_resp;

    // Write Channel FSM
    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            w_state       <= W_IDLE;
            axi_awvalid   <= 0;
            axi_wvalid    <= 0;
            axi_bready    <= 0;
            wr_busy       <= 0;
            wr_done       <= 0;
            w_timeout_cnt <= 0;
        end else begin
            wr_done <= 0;
            case (w_state)
                W_IDLE: begin
                    w_timeout_cnt <= 0;
                    if (usr_write_req) begin
                        w_state     <= W_AW_W;
                        axi_awaddr  <= usr_awaddr;
                        axi_wdata   <= usr_wdata;
                        axi_awvalid <= 1'b1;
                        axi_wvalid  <= 1'b1;
                        wr_busy     <= 1'b1;
                    end else wr_busy <= 1'b0;
                end

                W_AW_W: begin
                    w_timeout_cnt <= w_timeout_cnt + 1;
                    // Address/Data handshake
                    if (M_AXI_AWREADY && axi_awvalid) axi_awvalid <= 1'b0;
                    if (M_AXI_WREADY  && axi_wvalid)  axi_wvalid  <= 1'b0;

                    if (!axi_awvalid && !axi_wvalid) begin
                        axi_bready    <= 1'b1;
                        w_state       <= W_B;
                        w_timeout_cnt <= 0;
                    end else if (w_timeout_cnt >= TIMEOUT_VAL) begin
                        axi_awvalid <= 1'b0;
                        axi_wvalid  <= 1'b0;
                        wr_resp     <= 2'b10; // SLVERR
                        wr_done     <= 1'b1;
                        w_state     <= W_IDLE;
                    end
                end

                W_B: begin
                    w_timeout_cnt <= w_timeout_cnt + 1;
                    if (M_AXI_BVALID && axi_bready) begin
                        axi_bready <= 1'b0;
                        wr_resp    <= M_AXI_BRESP;
                        wr_done    <= 1'b1;
                        w_state    <= W_IDLE;
                    end else if (w_timeout_cnt >= TIMEOUT_VAL) begin
                        axi_bready <= 1'b0;
                        wr_resp    <= 2'b10; 
                        wr_done    <= 1'b1;
                        w_state    <= W_IDLE;
                    end
                end
                default: w_state <= W_IDLE;
            endcase
        end
    end

    // Read Channel FSM
    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            r_state       <= R_IDLE;
            axi_arvalid   <= 0;
            axi_rready    <= 0;
            rd_busy       <= 0;
            rd_done       <= 0;
            usr_rdata     <= 0;
            r_timeout_cnt <= 0;
        end else begin
            rd_done <= 0;
            case (r_state)
                R_IDLE: begin
                    r_timeout_cnt <= 0;
                    if (usr_read_req) begin
                        r_state     <= R_AR;
                        axi_araddr  <= usr_araddr;
                        axi_arvalid <= 1'b1;
                        rd_busy     <= 1'b1;
                    end else rd_busy <= 1'b0;
                end

                R_AR: begin
                    r_timeout_cnt <= r_timeout_cnt + 1;
                    if (M_AXI_ARREADY && axi_arvalid) begin
                        axi_arvalid   <= 1'b0;
                        axi_rready    <= 1'b1;
                        r_state       <= R_R;
                        r_timeout_cnt <= 0;
                    end else if (r_timeout_cnt >= TIMEOUT_VAL) begin
                        axi_arvalid   <= 1'b0;
                        rd_resp       <= 2'b10;
                        rd_done       <= 1'b1;
                        r_state       <= R_IDLE;
                    end
                end

                R_R: begin
                    r_timeout_cnt <= r_timeout_cnt + 1;
                    if (M_AXI_RVALID && axi_rready) begin
                        axi_rready <= 1'b0;
                        usr_rdata  <= M_AXI_RDATA;
                        rd_resp    <= M_AXI_RRESP;
                        rd_done    <= 1'b1;
                        r_state    <= R_IDLE;
                    end else if (r_timeout_cnt >= TIMEOUT_VAL) begin
                        axi_rready <= 1'b0;
                        rd_resp    <= 2'b10;
                        rd_done    <= 1'b1;
                        r_state    <= R_IDLE;
                    end
                end
                default: r_state <= R_IDLE;
            endcase
        end
    end
endmodule