module ram_8x324 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input [2:0] R0_addr;
	input R0_en;
	input R0_clk;
	output wire [323:0] R0_data;
	input [2:0] W0_addr;
	input W0_en;
	input W0_clk;
	input [323:0] W0_data;
	reg [323:0] Memory [0:7];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	assign R0_data = (R0_en ? Memory[R0_addr] : 324'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue8_Vec2_FetchPacket (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_0_inst,
	io_enq_bits_0_pc,
	io_enq_bits_0_valid,
	io_enq_bits_0_pred_taken,
	io_enq_bits_0_pred_target,
	io_enq_bits_1_inst,
	io_enq_bits_1_pc,
	io_enq_bits_1_valid,
	io_enq_bits_1_pred_taken,
	io_enq_bits_1_pred_target,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_0_inst,
	io_deq_bits_0_pc,
	io_deq_bits_0_valid,
	io_deq_bits_0_pred_taken,
	io_deq_bits_0_pred_target,
	io_deq_bits_1_inst,
	io_deq_bits_1_pc,
	io_deq_bits_1_valid,
	io_deq_bits_1_pred_taken,
	io_deq_bits_1_pred_target
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input [31:0] io_enq_bits_0_inst;
	input [63:0] io_enq_bits_0_pc;
	input io_enq_bits_0_valid;
	input io_enq_bits_0_pred_taken;
	input [63:0] io_enq_bits_0_pred_target;
	input [31:0] io_enq_bits_1_inst;
	input [63:0] io_enq_bits_1_pc;
	input io_enq_bits_1_valid;
	input io_enq_bits_1_pred_taken;
	input [63:0] io_enq_bits_1_pred_target;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [31:0] io_deq_bits_0_inst;
	output wire [63:0] io_deq_bits_0_pc;
	output wire io_deq_bits_0_valid;
	output wire io_deq_bits_0_pred_taken;
	output wire [63:0] io_deq_bits_0_pred_target;
	output wire [31:0] io_deq_bits_1_inst;
	output wire [63:0] io_deq_bits_1_pc;
	output wire io_deq_bits_1_valid;
	output wire io_deq_bits_1_pred_taken;
	output wire [63:0] io_deq_bits_1_pred_target;
	wire [323:0] _ram_ext_R0_data;
	reg [2:0] enq_ptr_value;
	reg [2:0] deq_ptr_value;
	reg maybe_full;
	wire ptr_match = enq_ptr_value == deq_ptr_value;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			enq_ptr_value <= 3'h0;
			deq_ptr_value <= 3'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				enq_ptr_value <= enq_ptr_value + 3'h1;
			if (do_deq)
				deq_ptr_value <= deq_ptr_value + 3'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	ram_8x324 ram_ext(
		.R0_addr(deq_ptr_value),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(enq_ptr_value),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_1_pred_target, io_enq_bits_1_pred_taken, io_enq_bits_1_valid, io_enq_bits_1_pc, io_enq_bits_1_inst, io_enq_bits_0_pred_target, io_enq_bits_0_pred_taken, io_enq_bits_0_valid, io_enq_bits_0_pc, io_enq_bits_0_inst})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_0_inst = _ram_ext_R0_data[31:0];
	assign io_deq_bits_0_pc = _ram_ext_R0_data[95:32];
	assign io_deq_bits_0_valid = _ram_ext_R0_data[96];
	assign io_deq_bits_0_pred_taken = _ram_ext_R0_data[97];
	assign io_deq_bits_0_pred_target = _ram_ext_R0_data[161:98];
	assign io_deq_bits_1_inst = _ram_ext_R0_data[193:162];
	assign io_deq_bits_1_pc = _ram_ext_R0_data[257:194];
	assign io_deq_bits_1_valid = _ram_ext_R0_data[258];
	assign io_deq_bits_1_pred_taken = _ram_ext_R0_data[259];
	assign io_deq_bits_1_pred_target = _ram_ext_R0_data[323:260];
endmodule
module FrontEnd (
	clock,
	reset,
	io_imem_req_ready,
	io_imem_req_valid,
	io_imem_req_bits_addr,
	io_imem_resp_valid,
	io_imem_resp_bits_data,
	io_fetch_packet_ready,
	io_fetch_packet_valid,
	io_fetch_packet_bits_0_inst,
	io_fetch_packet_bits_0_pc,
	io_fetch_packet_bits_0_valid,
	io_fetch_packet_bits_0_pred_taken,
	io_fetch_packet_bits_0_pred_target,
	io_fetch_packet_bits_1_inst,
	io_fetch_packet_bits_1_pc,
	io_fetch_packet_bits_1_valid,
	io_fetch_packet_bits_1_pred_taken,
	io_fetch_packet_bits_1_pred_target,
	io_redirect_valid,
	io_redirect_pc,
	io_bpu_update_valid,
	io_bpu_update_bits_pc,
	io_bpu_update_bits_target,
	io_bpu_update_bits_taken
);
	input clock;
	input reset;
	input io_imem_req_ready;
	output wire io_imem_req_valid;
	output wire [63:0] io_imem_req_bits_addr;
	input io_imem_resp_valid;
	input [63:0] io_imem_resp_bits_data;
	input io_fetch_packet_ready;
	output wire io_fetch_packet_valid;
	output wire [31:0] io_fetch_packet_bits_0_inst;
	output wire [63:0] io_fetch_packet_bits_0_pc;
	output wire io_fetch_packet_bits_0_valid;
	output wire io_fetch_packet_bits_0_pred_taken;
	output wire [63:0] io_fetch_packet_bits_0_pred_target;
	output wire [31:0] io_fetch_packet_bits_1_inst;
	output wire [63:0] io_fetch_packet_bits_1_pc;
	output wire io_fetch_packet_bits_1_valid;
	output wire io_fetch_packet_bits_1_pred_taken;
	output wire [63:0] io_fetch_packet_bits_1_pred_target;
	input io_redirect_valid;
	input [63:0] io_redirect_pc;
	input io_bpu_update_valid;
	input [63:0] io_bpu_update_bits_pc;
	input [63:0] io_bpu_update_bits_target;
	input io_bpu_update_bits_taken;
	wire inst0_pred_taken;
	wire is_unaligned;
	wire _fq_io_enq_ready;
	reg [63:0] pc_reg;
	reg btb_valid_0;
	reg btb_valid_1;
	reg btb_valid_2;
	reg btb_valid_3;
	reg btb_valid_4;
	reg btb_valid_5;
	reg btb_valid_6;
	reg btb_valid_7;
	reg btb_valid_8;
	reg btb_valid_9;
	reg btb_valid_10;
	reg btb_valid_11;
	reg btb_valid_12;
	reg btb_valid_13;
	reg btb_valid_14;
	reg btb_valid_15;
	reg btb_valid_16;
	reg btb_valid_17;
	reg btb_valid_18;
	reg btb_valid_19;
	reg btb_valid_20;
	reg btb_valid_21;
	reg btb_valid_22;
	reg btb_valid_23;
	reg btb_valid_24;
	reg btb_valid_25;
	reg btb_valid_26;
	reg btb_valid_27;
	reg btb_valid_28;
	reg btb_valid_29;
	reg btb_valid_30;
	reg btb_valid_31;
	reg btb_valid_32;
	reg btb_valid_33;
	reg btb_valid_34;
	reg btb_valid_35;
	reg btb_valid_36;
	reg btb_valid_37;
	reg btb_valid_38;
	reg btb_valid_39;
	reg btb_valid_40;
	reg btb_valid_41;
	reg btb_valid_42;
	reg btb_valid_43;
	reg btb_valid_44;
	reg btb_valid_45;
	reg btb_valid_46;
	reg btb_valid_47;
	reg btb_valid_48;
	reg btb_valid_49;
	reg btb_valid_50;
	reg btb_valid_51;
	reg btb_valid_52;
	reg btb_valid_53;
	reg btb_valid_54;
	reg btb_valid_55;
	reg btb_valid_56;
	reg btb_valid_57;
	reg btb_valid_58;
	reg btb_valid_59;
	reg btb_valid_60;
	reg btb_valid_61;
	reg btb_valid_62;
	reg btb_valid_63;
	reg [54:0] btb_tag_0;
	reg [54:0] btb_tag_1;
	reg [54:0] btb_tag_2;
	reg [54:0] btb_tag_3;
	reg [54:0] btb_tag_4;
	reg [54:0] btb_tag_5;
	reg [54:0] btb_tag_6;
	reg [54:0] btb_tag_7;
	reg [54:0] btb_tag_8;
	reg [54:0] btb_tag_9;
	reg [54:0] btb_tag_10;
	reg [54:0] btb_tag_11;
	reg [54:0] btb_tag_12;
	reg [54:0] btb_tag_13;
	reg [54:0] btb_tag_14;
	reg [54:0] btb_tag_15;
	reg [54:0] btb_tag_16;
	reg [54:0] btb_tag_17;
	reg [54:0] btb_tag_18;
	reg [54:0] btb_tag_19;
	reg [54:0] btb_tag_20;
	reg [54:0] btb_tag_21;
	reg [54:0] btb_tag_22;
	reg [54:0] btb_tag_23;
	reg [54:0] btb_tag_24;
	reg [54:0] btb_tag_25;
	reg [54:0] btb_tag_26;
	reg [54:0] btb_tag_27;
	reg [54:0] btb_tag_28;
	reg [54:0] btb_tag_29;
	reg [54:0] btb_tag_30;
	reg [54:0] btb_tag_31;
	reg [54:0] btb_tag_32;
	reg [54:0] btb_tag_33;
	reg [54:0] btb_tag_34;
	reg [54:0] btb_tag_35;
	reg [54:0] btb_tag_36;
	reg [54:0] btb_tag_37;
	reg [54:0] btb_tag_38;
	reg [54:0] btb_tag_39;
	reg [54:0] btb_tag_40;
	reg [54:0] btb_tag_41;
	reg [54:0] btb_tag_42;
	reg [54:0] btb_tag_43;
	reg [54:0] btb_tag_44;
	reg [54:0] btb_tag_45;
	reg [54:0] btb_tag_46;
	reg [54:0] btb_tag_47;
	reg [54:0] btb_tag_48;
	reg [54:0] btb_tag_49;
	reg [54:0] btb_tag_50;
	reg [54:0] btb_tag_51;
	reg [54:0] btb_tag_52;
	reg [54:0] btb_tag_53;
	reg [54:0] btb_tag_54;
	reg [54:0] btb_tag_55;
	reg [54:0] btb_tag_56;
	reg [54:0] btb_tag_57;
	reg [54:0] btb_tag_58;
	reg [54:0] btb_tag_59;
	reg [54:0] btb_tag_60;
	reg [54:0] btb_tag_61;
	reg [54:0] btb_tag_62;
	reg [54:0] btb_tag_63;
	reg [63:0] btb_target_0;
	reg [63:0] btb_target_1;
	reg [63:0] btb_target_2;
	reg [63:0] btb_target_3;
	reg [63:0] btb_target_4;
	reg [63:0] btb_target_5;
	reg [63:0] btb_target_6;
	reg [63:0] btb_target_7;
	reg [63:0] btb_target_8;
	reg [63:0] btb_target_9;
	reg [63:0] btb_target_10;
	reg [63:0] btb_target_11;
	reg [63:0] btb_target_12;
	reg [63:0] btb_target_13;
	reg [63:0] btb_target_14;
	reg [63:0] btb_target_15;
	reg [63:0] btb_target_16;
	reg [63:0] btb_target_17;
	reg [63:0] btb_target_18;
	reg [63:0] btb_target_19;
	reg [63:0] btb_target_20;
	reg [63:0] btb_target_21;
	reg [63:0] btb_target_22;
	reg [63:0] btb_target_23;
	reg [63:0] btb_target_24;
	reg [63:0] btb_target_25;
	reg [63:0] btb_target_26;
	reg [63:0] btb_target_27;
	reg [63:0] btb_target_28;
	reg [63:0] btb_target_29;
	reg [63:0] btb_target_30;
	reg [63:0] btb_target_31;
	reg [63:0] btb_target_32;
	reg [63:0] btb_target_33;
	reg [63:0] btb_target_34;
	reg [63:0] btb_target_35;
	reg [63:0] btb_target_36;
	reg [63:0] btb_target_37;
	reg [63:0] btb_target_38;
	reg [63:0] btb_target_39;
	reg [63:0] btb_target_40;
	reg [63:0] btb_target_41;
	reg [63:0] btb_target_42;
	reg [63:0] btb_target_43;
	reg [63:0] btb_target_44;
	reg [63:0] btb_target_45;
	reg [63:0] btb_target_46;
	reg [63:0] btb_target_47;
	reg [63:0] btb_target_48;
	reg [63:0] btb_target_49;
	reg [63:0] btb_target_50;
	reg [63:0] btb_target_51;
	reg [63:0] btb_target_52;
	reg [63:0] btb_target_53;
	reg [63:0] btb_target_54;
	reg [63:0] btb_target_55;
	reg [63:0] btb_target_56;
	reg [63:0] btb_target_57;
	reg [63:0] btb_target_58;
	reg [63:0] btb_target_59;
	reg [63:0] btb_target_60;
	reg [63:0] btb_target_61;
	reg [63:0] btb_target_62;
	reg [63:0] btb_target_63;
	reg btb_slot_0;
	reg btb_slot_1;
	reg btb_slot_2;
	reg btb_slot_3;
	reg btb_slot_4;
	reg btb_slot_5;
	reg btb_slot_6;
	reg btb_slot_7;
	reg btb_slot_8;
	reg btb_slot_9;
	reg btb_slot_10;
	reg btb_slot_11;
	reg btb_slot_12;
	reg btb_slot_13;
	reg btb_slot_14;
	reg btb_slot_15;
	reg btb_slot_16;
	reg btb_slot_17;
	reg btb_slot_18;
	reg btb_slot_19;
	reg btb_slot_20;
	reg btb_slot_21;
	reg btb_slot_22;
	reg btb_slot_23;
	reg btb_slot_24;
	reg btb_slot_25;
	reg btb_slot_26;
	reg btb_slot_27;
	reg btb_slot_28;
	reg btb_slot_29;
	reg btb_slot_30;
	reg btb_slot_31;
	reg btb_slot_32;
	reg btb_slot_33;
	reg btb_slot_34;
	reg btb_slot_35;
	reg btb_slot_36;
	reg btb_slot_37;
	reg btb_slot_38;
	reg btb_slot_39;
	reg btb_slot_40;
	reg btb_slot_41;
	reg btb_slot_42;
	reg btb_slot_43;
	reg btb_slot_44;
	reg btb_slot_45;
	reg btb_slot_46;
	reg btb_slot_47;
	reg btb_slot_48;
	reg btb_slot_49;
	reg btb_slot_50;
	reg btb_slot_51;
	reg btb_slot_52;
	reg btb_slot_53;
	reg btb_slot_54;
	reg btb_slot_55;
	reg btb_slot_56;
	reg btb_slot_57;
	reg btb_slot_58;
	reg btb_slot_59;
	reg btb_slot_60;
	reg btb_slot_61;
	reg btb_slot_62;
	reg btb_slot_63;
	wire if1_fire = (_fq_io_enq_ready & io_imem_req_ready) & ~io_redirect_valid;
	reg [63:0] if2_pc_reg;
	reg if2_valid;
	reg if2_pred_taken;
	reg [63:0] if2_pred_target;
	reg if2_pred_slot;
	reg flush_in_flight_REG;
	assign is_unaligned = if2_pc_reg[2];
	assign inst0_pred_taken = (if2_pred_taken & ~if2_pred_slot) & ~is_unaligned;
	always @(posedge clock) begin : sv2v_autoblock_1
		reg _GEN;
		reg _GEN_0;
		reg _GEN_1;
		reg _GEN_2;
		reg _GEN_3;
		reg _GEN_4;
		reg _GEN_5;
		reg _GEN_6;
		reg _GEN_7;
		reg _GEN_8;
		reg _GEN_9;
		reg _GEN_10;
		reg _GEN_11;
		reg _GEN_12;
		reg _GEN_13;
		reg _GEN_14;
		reg _GEN_15;
		reg _GEN_16;
		reg _GEN_17;
		reg _GEN_18;
		reg _GEN_19;
		reg _GEN_20;
		reg _GEN_21;
		reg _GEN_22;
		reg _GEN_23;
		reg _GEN_24;
		reg _GEN_25;
		reg _GEN_26;
		reg _GEN_27;
		reg _GEN_28;
		reg _GEN_29;
		reg _GEN_30;
		reg _GEN_31;
		reg _GEN_32;
		reg _GEN_33;
		reg _GEN_34;
		reg _GEN_35;
		reg _GEN_36;
		reg _GEN_37;
		reg _GEN_38;
		reg _GEN_39;
		reg _GEN_40;
		reg _GEN_41;
		reg _GEN_42;
		reg _GEN_43;
		reg _GEN_44;
		reg _GEN_45;
		reg _GEN_46;
		reg _GEN_47;
		reg _GEN_48;
		reg _GEN_49;
		reg _GEN_50;
		reg _GEN_51;
		reg _GEN_52;
		reg _GEN_53;
		reg _GEN_54;
		reg _GEN_55;
		reg _GEN_56;
		reg _GEN_57;
		reg _GEN_58;
		reg _GEN_59;
		reg _GEN_60;
		reg _GEN_61;
		reg _GEN_62;
		_GEN = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h00);
		_GEN_0 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h01);
		_GEN_1 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h02);
		_GEN_2 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h03);
		_GEN_3 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h04);
		_GEN_4 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h05);
		_GEN_5 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h06);
		_GEN_6 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h07);
		_GEN_7 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h08);
		_GEN_8 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h09);
		_GEN_9 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h0a);
		_GEN_10 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h0b);
		_GEN_11 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h0c);
		_GEN_12 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h0d);
		_GEN_13 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h0e);
		_GEN_14 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h0f);
		_GEN_15 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h10);
		_GEN_16 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h11);
		_GEN_17 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h12);
		_GEN_18 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h13);
		_GEN_19 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h14);
		_GEN_20 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h15);
		_GEN_21 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h16);
		_GEN_22 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h17);
		_GEN_23 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h18);
		_GEN_24 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h19);
		_GEN_25 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h1a);
		_GEN_26 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h1b);
		_GEN_27 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h1c);
		_GEN_28 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h1d);
		_GEN_29 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h1e);
		_GEN_30 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h1f);
		_GEN_31 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h20);
		_GEN_32 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h21);
		_GEN_33 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h22);
		_GEN_34 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h23);
		_GEN_35 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h24);
		_GEN_36 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h25);
		_GEN_37 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h26);
		_GEN_38 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h27);
		_GEN_39 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h28);
		_GEN_40 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h29);
		_GEN_41 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h2a);
		_GEN_42 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h2b);
		_GEN_43 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h2c);
		_GEN_44 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h2d);
		_GEN_45 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h2e);
		_GEN_46 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h2f);
		_GEN_47 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h30);
		_GEN_48 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h31);
		_GEN_49 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h32);
		_GEN_50 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h33);
		_GEN_51 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h34);
		_GEN_52 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h35);
		_GEN_53 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h36);
		_GEN_54 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h37);
		_GEN_55 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h38);
		_GEN_56 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h39);
		_GEN_57 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h3a);
		_GEN_58 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h3b);
		_GEN_59 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h3c);
		_GEN_60 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h3d);
		_GEN_61 = io_bpu_update_valid & (io_bpu_update_bits_pc[8:3] == 6'h3e);
		_GEN_62 = io_bpu_update_valid & (&io_bpu_update_bits_pc[8:3]);
		if (reset) begin
			pc_reg <= 64'h0000000080000000;
			btb_valid_0 <= 1'h0;
			btb_valid_1 <= 1'h0;
			btb_valid_2 <= 1'h0;
			btb_valid_3 <= 1'h0;
			btb_valid_4 <= 1'h0;
			btb_valid_5 <= 1'h0;
			btb_valid_6 <= 1'h0;
			btb_valid_7 <= 1'h0;
			btb_valid_8 <= 1'h0;
			btb_valid_9 <= 1'h0;
			btb_valid_10 <= 1'h0;
			btb_valid_11 <= 1'h0;
			btb_valid_12 <= 1'h0;
			btb_valid_13 <= 1'h0;
			btb_valid_14 <= 1'h0;
			btb_valid_15 <= 1'h0;
			btb_valid_16 <= 1'h0;
			btb_valid_17 <= 1'h0;
			btb_valid_18 <= 1'h0;
			btb_valid_19 <= 1'h0;
			btb_valid_20 <= 1'h0;
			btb_valid_21 <= 1'h0;
			btb_valid_22 <= 1'h0;
			btb_valid_23 <= 1'h0;
			btb_valid_24 <= 1'h0;
			btb_valid_25 <= 1'h0;
			btb_valid_26 <= 1'h0;
			btb_valid_27 <= 1'h0;
			btb_valid_28 <= 1'h0;
			btb_valid_29 <= 1'h0;
			btb_valid_30 <= 1'h0;
			btb_valid_31 <= 1'h0;
			btb_valid_32 <= 1'h0;
			btb_valid_33 <= 1'h0;
			btb_valid_34 <= 1'h0;
			btb_valid_35 <= 1'h0;
			btb_valid_36 <= 1'h0;
			btb_valid_37 <= 1'h0;
			btb_valid_38 <= 1'h0;
			btb_valid_39 <= 1'h0;
			btb_valid_40 <= 1'h0;
			btb_valid_41 <= 1'h0;
			btb_valid_42 <= 1'h0;
			btb_valid_43 <= 1'h0;
			btb_valid_44 <= 1'h0;
			btb_valid_45 <= 1'h0;
			btb_valid_46 <= 1'h0;
			btb_valid_47 <= 1'h0;
			btb_valid_48 <= 1'h0;
			btb_valid_49 <= 1'h0;
			btb_valid_50 <= 1'h0;
			btb_valid_51 <= 1'h0;
			btb_valid_52 <= 1'h0;
			btb_valid_53 <= 1'h0;
			btb_valid_54 <= 1'h0;
			btb_valid_55 <= 1'h0;
			btb_valid_56 <= 1'h0;
			btb_valid_57 <= 1'h0;
			btb_valid_58 <= 1'h0;
			btb_valid_59 <= 1'h0;
			btb_valid_60 <= 1'h0;
			btb_valid_61 <= 1'h0;
			btb_valid_62 <= 1'h0;
			btb_valid_63 <= 1'h0;
			if2_valid <= 1'h0;
			if2_pred_taken <= 1'h0;
			if2_pred_target <= 64'h0000000000000000;
			if2_pred_slot <= 1'h0;
			flush_in_flight_REG <= 1'h0;
		end
		else begin : sv2v_autoblock_2
			reg [63:0] _GEN_63;
			reg [3519:0] _GEN_64;
			reg btb_hit;
			reg [4095:0] _GEN_65;
			reg [63:0] _GEN_66;
			_GEN_63 = {btb_valid_63, btb_valid_62, btb_valid_61, btb_valid_60, btb_valid_59, btb_valid_58, btb_valid_57, btb_valid_56, btb_valid_55, btb_valid_54, btb_valid_53, btb_valid_52, btb_valid_51, btb_valid_50, btb_valid_49, btb_valid_48, btb_valid_47, btb_valid_46, btb_valid_45, btb_valid_44, btb_valid_43, btb_valid_42, btb_valid_41, btb_valid_40, btb_valid_39, btb_valid_38, btb_valid_37, btb_valid_36, btb_valid_35, btb_valid_34, btb_valid_33, btb_valid_32, btb_valid_31, btb_valid_30, btb_valid_29, btb_valid_28, btb_valid_27, btb_valid_26, btb_valid_25, btb_valid_24, btb_valid_23, btb_valid_22, btb_valid_21, btb_valid_20, btb_valid_19, btb_valid_18, btb_valid_17, btb_valid_16, btb_valid_15, btb_valid_14, btb_valid_13, btb_valid_12, btb_valid_11, btb_valid_10, btb_valid_9, btb_valid_8, btb_valid_7, btb_valid_6, btb_valid_5, btb_valid_4, btb_valid_3, btb_valid_2, btb_valid_1, btb_valid_0};
			_GEN_64 = {btb_tag_63, btb_tag_62, btb_tag_61, btb_tag_60, btb_tag_59, btb_tag_58, btb_tag_57, btb_tag_56, btb_tag_55, btb_tag_54, btb_tag_53, btb_tag_52, btb_tag_51, btb_tag_50, btb_tag_49, btb_tag_48, btb_tag_47, btb_tag_46, btb_tag_45, btb_tag_44, btb_tag_43, btb_tag_42, btb_tag_41, btb_tag_40, btb_tag_39, btb_tag_38, btb_tag_37, btb_tag_36, btb_tag_35, btb_tag_34, btb_tag_33, btb_tag_32, btb_tag_31, btb_tag_30, btb_tag_29, btb_tag_28, btb_tag_27, btb_tag_26, btb_tag_25, btb_tag_24, btb_tag_23, btb_tag_22, btb_tag_21, btb_tag_20, btb_tag_19, btb_tag_18, btb_tag_17, btb_tag_16, btb_tag_15, btb_tag_14, btb_tag_13, btb_tag_12, btb_tag_11, btb_tag_10, btb_tag_9, btb_tag_8, btb_tag_7, btb_tag_6, btb_tag_5, btb_tag_4, btb_tag_3, btb_tag_2, btb_tag_1, btb_tag_0};
			_GEN_65 = {btb_target_63, btb_target_62, btb_target_61, btb_target_60, btb_target_59, btb_target_58, btb_target_57, btb_target_56, btb_target_55, btb_target_54, btb_target_53, btb_target_52, btb_target_51, btb_target_50, btb_target_49, btb_target_48, btb_target_47, btb_target_46, btb_target_45, btb_target_44, btb_target_43, btb_target_42, btb_target_41, btb_target_40, btb_target_39, btb_target_38, btb_target_37, btb_target_36, btb_target_35, btb_target_34, btb_target_33, btb_target_32, btb_target_31, btb_target_30, btb_target_29, btb_target_28, btb_target_27, btb_target_26, btb_target_25, btb_target_24, btb_target_23, btb_target_22, btb_target_21, btb_target_20, btb_target_19, btb_target_18, btb_target_17, btb_target_16, btb_target_15, btb_target_14, btb_target_13, btb_target_12, btb_target_11, btb_target_10, btb_target_9, btb_target_8, btb_target_7, btb_target_6, btb_target_5, btb_target_4, btb_target_3, btb_target_2, btb_target_1, btb_target_0};
			btb_hit = _GEN_63[pc_reg[8:3]] & (_GEN_64[pc_reg[8:3] * 55+:55] == pc_reg[63:9]);
			_GEN_66 = _GEN_65[pc_reg[8:3] * 64+:64];
			if (io_redirect_valid)
				pc_reg <= io_redirect_pc;
			else if (if1_fire & btb_hit)
				pc_reg <= _GEN_66;
			else if (if1_fire)
				pc_reg <= (pc_reg & 64'hfffffffffffffff8) + 64'h0000000000000008;
			if (_GEN)
				btb_valid_0 <= io_bpu_update_bits_taken;
			if (_GEN_0)
				btb_valid_1 <= io_bpu_update_bits_taken;
			if (_GEN_1)
				btb_valid_2 <= io_bpu_update_bits_taken;
			if (_GEN_2)
				btb_valid_3 <= io_bpu_update_bits_taken;
			if (_GEN_3)
				btb_valid_4 <= io_bpu_update_bits_taken;
			if (_GEN_4)
				btb_valid_5 <= io_bpu_update_bits_taken;
			if (_GEN_5)
				btb_valid_6 <= io_bpu_update_bits_taken;
			if (_GEN_6)
				btb_valid_7 <= io_bpu_update_bits_taken;
			if (_GEN_7)
				btb_valid_8 <= io_bpu_update_bits_taken;
			if (_GEN_8)
				btb_valid_9 <= io_bpu_update_bits_taken;
			if (_GEN_9)
				btb_valid_10 <= io_bpu_update_bits_taken;
			if (_GEN_10)
				btb_valid_11 <= io_bpu_update_bits_taken;
			if (_GEN_11)
				btb_valid_12 <= io_bpu_update_bits_taken;
			if (_GEN_12)
				btb_valid_13 <= io_bpu_update_bits_taken;
			if (_GEN_13)
				btb_valid_14 <= io_bpu_update_bits_taken;
			if (_GEN_14)
				btb_valid_15 <= io_bpu_update_bits_taken;
			if (_GEN_15)
				btb_valid_16 <= io_bpu_update_bits_taken;
			if (_GEN_16)
				btb_valid_17 <= io_bpu_update_bits_taken;
			if (_GEN_17)
				btb_valid_18 <= io_bpu_update_bits_taken;
			if (_GEN_18)
				btb_valid_19 <= io_bpu_update_bits_taken;
			if (_GEN_19)
				btb_valid_20 <= io_bpu_update_bits_taken;
			if (_GEN_20)
				btb_valid_21 <= io_bpu_update_bits_taken;
			if (_GEN_21)
				btb_valid_22 <= io_bpu_update_bits_taken;
			if (_GEN_22)
				btb_valid_23 <= io_bpu_update_bits_taken;
			if (_GEN_23)
				btb_valid_24 <= io_bpu_update_bits_taken;
			if (_GEN_24)
				btb_valid_25 <= io_bpu_update_bits_taken;
			if (_GEN_25)
				btb_valid_26 <= io_bpu_update_bits_taken;
			if (_GEN_26)
				btb_valid_27 <= io_bpu_update_bits_taken;
			if (_GEN_27)
				btb_valid_28 <= io_bpu_update_bits_taken;
			if (_GEN_28)
				btb_valid_29 <= io_bpu_update_bits_taken;
			if (_GEN_29)
				btb_valid_30 <= io_bpu_update_bits_taken;
			if (_GEN_30)
				btb_valid_31 <= io_bpu_update_bits_taken;
			if (_GEN_31)
				btb_valid_32 <= io_bpu_update_bits_taken;
			if (_GEN_32)
				btb_valid_33 <= io_bpu_update_bits_taken;
			if (_GEN_33)
				btb_valid_34 <= io_bpu_update_bits_taken;
			if (_GEN_34)
				btb_valid_35 <= io_bpu_update_bits_taken;
			if (_GEN_35)
				btb_valid_36 <= io_bpu_update_bits_taken;
			if (_GEN_36)
				btb_valid_37 <= io_bpu_update_bits_taken;
			if (_GEN_37)
				btb_valid_38 <= io_bpu_update_bits_taken;
			if (_GEN_38)
				btb_valid_39 <= io_bpu_update_bits_taken;
			if (_GEN_39)
				btb_valid_40 <= io_bpu_update_bits_taken;
			if (_GEN_40)
				btb_valid_41 <= io_bpu_update_bits_taken;
			if (_GEN_41)
				btb_valid_42 <= io_bpu_update_bits_taken;
			if (_GEN_42)
				btb_valid_43 <= io_bpu_update_bits_taken;
			if (_GEN_43)
				btb_valid_44 <= io_bpu_update_bits_taken;
			if (_GEN_44)
				btb_valid_45 <= io_bpu_update_bits_taken;
			if (_GEN_45)
				btb_valid_46 <= io_bpu_update_bits_taken;
			if (_GEN_46)
				btb_valid_47 <= io_bpu_update_bits_taken;
			if (_GEN_47)
				btb_valid_48 <= io_bpu_update_bits_taken;
			if (_GEN_48)
				btb_valid_49 <= io_bpu_update_bits_taken;
			if (_GEN_49)
				btb_valid_50 <= io_bpu_update_bits_taken;
			if (_GEN_50)
				btb_valid_51 <= io_bpu_update_bits_taken;
			if (_GEN_51)
				btb_valid_52 <= io_bpu_update_bits_taken;
			if (_GEN_52)
				btb_valid_53 <= io_bpu_update_bits_taken;
			if (_GEN_53)
				btb_valid_54 <= io_bpu_update_bits_taken;
			if (_GEN_54)
				btb_valid_55 <= io_bpu_update_bits_taken;
			if (_GEN_55)
				btb_valid_56 <= io_bpu_update_bits_taken;
			if (_GEN_56)
				btb_valid_57 <= io_bpu_update_bits_taken;
			if (_GEN_57)
				btb_valid_58 <= io_bpu_update_bits_taken;
			if (_GEN_58)
				btb_valid_59 <= io_bpu_update_bits_taken;
			if (_GEN_59)
				btb_valid_60 <= io_bpu_update_bits_taken;
			if (_GEN_60)
				btb_valid_61 <= io_bpu_update_bits_taken;
			if (_GEN_61)
				btb_valid_62 <= io_bpu_update_bits_taken;
			if (_GEN_62)
				btb_valid_63 <= io_bpu_update_bits_taken;
			if2_valid <= if1_fire;
			if (if1_fire) begin : sv2v_autoblock_3
				reg [63:0] _GEN_67;
				_GEN_67 = {btb_slot_63, btb_slot_62, btb_slot_61, btb_slot_60, btb_slot_59, btb_slot_58, btb_slot_57, btb_slot_56, btb_slot_55, btb_slot_54, btb_slot_53, btb_slot_52, btb_slot_51, btb_slot_50, btb_slot_49, btb_slot_48, btb_slot_47, btb_slot_46, btb_slot_45, btb_slot_44, btb_slot_43, btb_slot_42, btb_slot_41, btb_slot_40, btb_slot_39, btb_slot_38, btb_slot_37, btb_slot_36, btb_slot_35, btb_slot_34, btb_slot_33, btb_slot_32, btb_slot_31, btb_slot_30, btb_slot_29, btb_slot_28, btb_slot_27, btb_slot_26, btb_slot_25, btb_slot_24, btb_slot_23, btb_slot_22, btb_slot_21, btb_slot_20, btb_slot_19, btb_slot_18, btb_slot_17, btb_slot_16, btb_slot_15, btb_slot_14, btb_slot_13, btb_slot_12, btb_slot_11, btb_slot_10, btb_slot_9, btb_slot_8, btb_slot_7, btb_slot_6, btb_slot_5, btb_slot_4, btb_slot_3, btb_slot_2, btb_slot_1, btb_slot_0};
				if2_pred_taken <= btb_hit;
				if2_pred_target <= _GEN_66;
				if2_pred_slot <= _GEN_67[pc_reg[8:3]];
			end
			flush_in_flight_REG <= io_redirect_valid;
		end
		if (_GEN) begin
			btb_tag_0 <= io_bpu_update_bits_pc[63:9];
			btb_target_0 <= io_bpu_update_bits_target;
			btb_slot_0 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_0) begin
			btb_tag_1 <= io_bpu_update_bits_pc[63:9];
			btb_target_1 <= io_bpu_update_bits_target;
			btb_slot_1 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_1) begin
			btb_tag_2 <= io_bpu_update_bits_pc[63:9];
			btb_target_2 <= io_bpu_update_bits_target;
			btb_slot_2 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_2) begin
			btb_tag_3 <= io_bpu_update_bits_pc[63:9];
			btb_target_3 <= io_bpu_update_bits_target;
			btb_slot_3 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_3) begin
			btb_tag_4 <= io_bpu_update_bits_pc[63:9];
			btb_target_4 <= io_bpu_update_bits_target;
			btb_slot_4 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_4) begin
			btb_tag_5 <= io_bpu_update_bits_pc[63:9];
			btb_target_5 <= io_bpu_update_bits_target;
			btb_slot_5 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_5) begin
			btb_tag_6 <= io_bpu_update_bits_pc[63:9];
			btb_target_6 <= io_bpu_update_bits_target;
			btb_slot_6 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_6) begin
			btb_tag_7 <= io_bpu_update_bits_pc[63:9];
			btb_target_7 <= io_bpu_update_bits_target;
			btb_slot_7 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_7) begin
			btb_tag_8 <= io_bpu_update_bits_pc[63:9];
			btb_target_8 <= io_bpu_update_bits_target;
			btb_slot_8 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_8) begin
			btb_tag_9 <= io_bpu_update_bits_pc[63:9];
			btb_target_9 <= io_bpu_update_bits_target;
			btb_slot_9 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_9) begin
			btb_tag_10 <= io_bpu_update_bits_pc[63:9];
			btb_target_10 <= io_bpu_update_bits_target;
			btb_slot_10 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_10) begin
			btb_tag_11 <= io_bpu_update_bits_pc[63:9];
			btb_target_11 <= io_bpu_update_bits_target;
			btb_slot_11 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_11) begin
			btb_tag_12 <= io_bpu_update_bits_pc[63:9];
			btb_target_12 <= io_bpu_update_bits_target;
			btb_slot_12 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_12) begin
			btb_tag_13 <= io_bpu_update_bits_pc[63:9];
			btb_target_13 <= io_bpu_update_bits_target;
			btb_slot_13 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_13) begin
			btb_tag_14 <= io_bpu_update_bits_pc[63:9];
			btb_target_14 <= io_bpu_update_bits_target;
			btb_slot_14 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_14) begin
			btb_tag_15 <= io_bpu_update_bits_pc[63:9];
			btb_target_15 <= io_bpu_update_bits_target;
			btb_slot_15 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_15) begin
			btb_tag_16 <= io_bpu_update_bits_pc[63:9];
			btb_target_16 <= io_bpu_update_bits_target;
			btb_slot_16 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_16) begin
			btb_tag_17 <= io_bpu_update_bits_pc[63:9];
			btb_target_17 <= io_bpu_update_bits_target;
			btb_slot_17 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_17) begin
			btb_tag_18 <= io_bpu_update_bits_pc[63:9];
			btb_target_18 <= io_bpu_update_bits_target;
			btb_slot_18 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_18) begin
			btb_tag_19 <= io_bpu_update_bits_pc[63:9];
			btb_target_19 <= io_bpu_update_bits_target;
			btb_slot_19 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_19) begin
			btb_tag_20 <= io_bpu_update_bits_pc[63:9];
			btb_target_20 <= io_bpu_update_bits_target;
			btb_slot_20 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_20) begin
			btb_tag_21 <= io_bpu_update_bits_pc[63:9];
			btb_target_21 <= io_bpu_update_bits_target;
			btb_slot_21 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_21) begin
			btb_tag_22 <= io_bpu_update_bits_pc[63:9];
			btb_target_22 <= io_bpu_update_bits_target;
			btb_slot_22 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_22) begin
			btb_tag_23 <= io_bpu_update_bits_pc[63:9];
			btb_target_23 <= io_bpu_update_bits_target;
			btb_slot_23 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_23) begin
			btb_tag_24 <= io_bpu_update_bits_pc[63:9];
			btb_target_24 <= io_bpu_update_bits_target;
			btb_slot_24 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_24) begin
			btb_tag_25 <= io_bpu_update_bits_pc[63:9];
			btb_target_25 <= io_bpu_update_bits_target;
			btb_slot_25 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_25) begin
			btb_tag_26 <= io_bpu_update_bits_pc[63:9];
			btb_target_26 <= io_bpu_update_bits_target;
			btb_slot_26 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_26) begin
			btb_tag_27 <= io_bpu_update_bits_pc[63:9];
			btb_target_27 <= io_bpu_update_bits_target;
			btb_slot_27 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_27) begin
			btb_tag_28 <= io_bpu_update_bits_pc[63:9];
			btb_target_28 <= io_bpu_update_bits_target;
			btb_slot_28 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_28) begin
			btb_tag_29 <= io_bpu_update_bits_pc[63:9];
			btb_target_29 <= io_bpu_update_bits_target;
			btb_slot_29 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_29) begin
			btb_tag_30 <= io_bpu_update_bits_pc[63:9];
			btb_target_30 <= io_bpu_update_bits_target;
			btb_slot_30 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_30) begin
			btb_tag_31 <= io_bpu_update_bits_pc[63:9];
			btb_target_31 <= io_bpu_update_bits_target;
			btb_slot_31 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_31) begin
			btb_tag_32 <= io_bpu_update_bits_pc[63:9];
			btb_target_32 <= io_bpu_update_bits_target;
			btb_slot_32 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_32) begin
			btb_tag_33 <= io_bpu_update_bits_pc[63:9];
			btb_target_33 <= io_bpu_update_bits_target;
			btb_slot_33 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_33) begin
			btb_tag_34 <= io_bpu_update_bits_pc[63:9];
			btb_target_34 <= io_bpu_update_bits_target;
			btb_slot_34 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_34) begin
			btb_tag_35 <= io_bpu_update_bits_pc[63:9];
			btb_target_35 <= io_bpu_update_bits_target;
			btb_slot_35 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_35) begin
			btb_tag_36 <= io_bpu_update_bits_pc[63:9];
			btb_target_36 <= io_bpu_update_bits_target;
			btb_slot_36 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_36) begin
			btb_tag_37 <= io_bpu_update_bits_pc[63:9];
			btb_target_37 <= io_bpu_update_bits_target;
			btb_slot_37 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_37) begin
			btb_tag_38 <= io_bpu_update_bits_pc[63:9];
			btb_target_38 <= io_bpu_update_bits_target;
			btb_slot_38 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_38) begin
			btb_tag_39 <= io_bpu_update_bits_pc[63:9];
			btb_target_39 <= io_bpu_update_bits_target;
			btb_slot_39 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_39) begin
			btb_tag_40 <= io_bpu_update_bits_pc[63:9];
			btb_target_40 <= io_bpu_update_bits_target;
			btb_slot_40 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_40) begin
			btb_tag_41 <= io_bpu_update_bits_pc[63:9];
			btb_target_41 <= io_bpu_update_bits_target;
			btb_slot_41 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_41) begin
			btb_tag_42 <= io_bpu_update_bits_pc[63:9];
			btb_target_42 <= io_bpu_update_bits_target;
			btb_slot_42 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_42) begin
			btb_tag_43 <= io_bpu_update_bits_pc[63:9];
			btb_target_43 <= io_bpu_update_bits_target;
			btb_slot_43 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_43) begin
			btb_tag_44 <= io_bpu_update_bits_pc[63:9];
			btb_target_44 <= io_bpu_update_bits_target;
			btb_slot_44 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_44) begin
			btb_tag_45 <= io_bpu_update_bits_pc[63:9];
			btb_target_45 <= io_bpu_update_bits_target;
			btb_slot_45 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_45) begin
			btb_tag_46 <= io_bpu_update_bits_pc[63:9];
			btb_target_46 <= io_bpu_update_bits_target;
			btb_slot_46 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_46) begin
			btb_tag_47 <= io_bpu_update_bits_pc[63:9];
			btb_target_47 <= io_bpu_update_bits_target;
			btb_slot_47 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_47) begin
			btb_tag_48 <= io_bpu_update_bits_pc[63:9];
			btb_target_48 <= io_bpu_update_bits_target;
			btb_slot_48 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_48) begin
			btb_tag_49 <= io_bpu_update_bits_pc[63:9];
			btb_target_49 <= io_bpu_update_bits_target;
			btb_slot_49 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_49) begin
			btb_tag_50 <= io_bpu_update_bits_pc[63:9];
			btb_target_50 <= io_bpu_update_bits_target;
			btb_slot_50 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_50) begin
			btb_tag_51 <= io_bpu_update_bits_pc[63:9];
			btb_target_51 <= io_bpu_update_bits_target;
			btb_slot_51 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_51) begin
			btb_tag_52 <= io_bpu_update_bits_pc[63:9];
			btb_target_52 <= io_bpu_update_bits_target;
			btb_slot_52 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_52) begin
			btb_tag_53 <= io_bpu_update_bits_pc[63:9];
			btb_target_53 <= io_bpu_update_bits_target;
			btb_slot_53 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_53) begin
			btb_tag_54 <= io_bpu_update_bits_pc[63:9];
			btb_target_54 <= io_bpu_update_bits_target;
			btb_slot_54 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_54) begin
			btb_tag_55 <= io_bpu_update_bits_pc[63:9];
			btb_target_55 <= io_bpu_update_bits_target;
			btb_slot_55 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_55) begin
			btb_tag_56 <= io_bpu_update_bits_pc[63:9];
			btb_target_56 <= io_bpu_update_bits_target;
			btb_slot_56 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_56) begin
			btb_tag_57 <= io_bpu_update_bits_pc[63:9];
			btb_target_57 <= io_bpu_update_bits_target;
			btb_slot_57 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_57) begin
			btb_tag_58 <= io_bpu_update_bits_pc[63:9];
			btb_target_58 <= io_bpu_update_bits_target;
			btb_slot_58 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_58) begin
			btb_tag_59 <= io_bpu_update_bits_pc[63:9];
			btb_target_59 <= io_bpu_update_bits_target;
			btb_slot_59 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_59) begin
			btb_tag_60 <= io_bpu_update_bits_pc[63:9];
			btb_target_60 <= io_bpu_update_bits_target;
			btb_slot_60 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_60) begin
			btb_tag_61 <= io_bpu_update_bits_pc[63:9];
			btb_target_61 <= io_bpu_update_bits_target;
			btb_slot_61 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_61) begin
			btb_tag_62 <= io_bpu_update_bits_pc[63:9];
			btb_target_62 <= io_bpu_update_bits_target;
			btb_slot_62 <= io_bpu_update_bits_pc[2];
		end
		if (_GEN_62) begin
			btb_tag_63 <= io_bpu_update_bits_pc[63:9];
			btb_target_63 <= io_bpu_update_bits_target;
			btb_slot_63 <= io_bpu_update_bits_pc[2];
		end
		if (if1_fire)
			if2_pc_reg <= pc_reg;
	end
	Queue8_Vec2_FetchPacket fq(
		.clock(clock),
		.reset(reset | io_redirect_valid),
		.io_enq_ready(_fq_io_enq_ready),
		.io_enq_valid((if2_valid & io_imem_resp_valid) & ~(flush_in_flight_REG | io_redirect_valid)),
		.io_enq_bits_0_inst(io_imem_resp_bits_data[31:0]),
		.io_enq_bits_0_pc(if2_pc_reg & 64'hfffffffffffffff8),
		.io_enq_bits_0_valid(~is_unaligned),
		.io_enq_bits_0_pred_taken(inst0_pred_taken),
		.io_enq_bits_0_pred_target(if2_pred_target),
		.io_enq_bits_1_inst(io_imem_resp_bits_data[63:32]),
		.io_enq_bits_1_pc((if2_pc_reg & 64'hfffffffffffffff8) + 64'h0000000000000004),
		.io_enq_bits_1_valid(~inst0_pred_taken),
		.io_enq_bits_1_pred_taken((if2_pred_taken & if2_pred_slot) & ~inst0_pred_taken),
		.io_enq_bits_1_pred_target(if2_pred_target),
		.io_deq_ready(io_fetch_packet_ready),
		.io_deq_valid(io_fetch_packet_valid),
		.io_deq_bits_0_inst(io_fetch_packet_bits_0_inst),
		.io_deq_bits_0_pc(io_fetch_packet_bits_0_pc),
		.io_deq_bits_0_valid(io_fetch_packet_bits_0_valid),
		.io_deq_bits_0_pred_taken(io_fetch_packet_bits_0_pred_taken),
		.io_deq_bits_0_pred_target(io_fetch_packet_bits_0_pred_target),
		.io_deq_bits_1_inst(io_fetch_packet_bits_1_inst),
		.io_deq_bits_1_pc(io_fetch_packet_bits_1_pc),
		.io_deq_bits_1_valid(io_fetch_packet_bits_1_valid),
		.io_deq_bits_1_pred_taken(io_fetch_packet_bits_1_pred_taken),
		.io_deq_bits_1_pred_target(io_fetch_packet_bits_1_pred_target)
	);
	assign io_imem_req_valid = if1_fire;
	assign io_imem_req_bits_addr = pc_reg & 64'hfffffffffffffff8;
endmodule
module DecodeUnit (
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_0_inst,
	io_enq_bits_0_pc,
	io_enq_bits_0_valid,
	io_enq_bits_0_pred_taken,
	io_enq_bits_0_pred_target,
	io_enq_bits_1_inst,
	io_enq_bits_1_pc,
	io_enq_bits_1_valid,
	io_enq_bits_1_pred_taken,
	io_enq_bits_1_pred_target,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_0_valid,
	io_deq_bits_0_pc,
	io_deq_bits_0_inst,
	io_deq_bits_0_fu_code,
	io_deq_bits_0_alu_op,
	io_deq_bits_0_op1_sel,
	io_deq_bits_0_op2_sel,
	io_deq_bits_0_imm,
	io_deq_bits_0_imm_sel,
	io_deq_bits_0_is_w,
	io_deq_bits_0_mem_cmd,
	io_deq_bits_0_mem_size,
	io_deq_bits_0_mem_signed,
	io_deq_bits_0_br_type,
	io_deq_bits_0_l_rd,
	io_deq_bits_0_l_rs1,
	io_deq_bits_0_l_rs2,
	io_deq_bits_0_rf_wen,
	io_deq_bits_0_use_rs1,
	io_deq_bits_0_use_rs2,
	io_deq_bits_0_exception,
	io_deq_bits_0_pred_taken,
	io_deq_bits_0_pred_target,
	io_deq_bits_1_valid,
	io_deq_bits_1_pc,
	io_deq_bits_1_inst,
	io_deq_bits_1_fu_code,
	io_deq_bits_1_alu_op,
	io_deq_bits_1_op1_sel,
	io_deq_bits_1_op2_sel,
	io_deq_bits_1_imm,
	io_deq_bits_1_imm_sel,
	io_deq_bits_1_is_w,
	io_deq_bits_1_mem_cmd,
	io_deq_bits_1_mem_size,
	io_deq_bits_1_mem_signed,
	io_deq_bits_1_br_type,
	io_deq_bits_1_l_rd,
	io_deq_bits_1_l_rs1,
	io_deq_bits_1_l_rs2,
	io_deq_bits_1_rf_wen,
	io_deq_bits_1_use_rs1,
	io_deq_bits_1_use_rs2,
	io_deq_bits_1_exception,
	io_deq_bits_1_pred_taken,
	io_deq_bits_1_pred_target
);
	output wire io_enq_ready;
	input io_enq_valid;
	input [31:0] io_enq_bits_0_inst;
	input [63:0] io_enq_bits_0_pc;
	input io_enq_bits_0_valid;
	input io_enq_bits_0_pred_taken;
	input [63:0] io_enq_bits_0_pred_target;
	input [31:0] io_enq_bits_1_inst;
	input [63:0] io_enq_bits_1_pc;
	input io_enq_bits_1_valid;
	input io_enq_bits_1_pred_taken;
	input [63:0] io_enq_bits_1_pred_target;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire io_deq_bits_0_valid;
	output wire [63:0] io_deq_bits_0_pc;
	output wire [31:0] io_deq_bits_0_inst;
	output wire [5:0] io_deq_bits_0_fu_code;
	output wire [9:0] io_deq_bits_0_alu_op;
	output wire [1:0] io_deq_bits_0_op1_sel;
	output wire [2:0] io_deq_bits_0_op2_sel;
	output wire [63:0] io_deq_bits_0_imm;
	output wire [2:0] io_deq_bits_0_imm_sel;
	output wire io_deq_bits_0_is_w;
	output wire [2:0] io_deq_bits_0_mem_cmd;
	output wire [1:0] io_deq_bits_0_mem_size;
	output wire io_deq_bits_0_mem_signed;
	output wire [3:0] io_deq_bits_0_br_type;
	output wire [4:0] io_deq_bits_0_l_rd;
	output wire [4:0] io_deq_bits_0_l_rs1;
	output wire [4:0] io_deq_bits_0_l_rs2;
	output wire io_deq_bits_0_rf_wen;
	output wire io_deq_bits_0_use_rs1;
	output wire io_deq_bits_0_use_rs2;
	output wire io_deq_bits_0_exception;
	output wire io_deq_bits_0_pred_taken;
	output wire [63:0] io_deq_bits_0_pred_target;
	output wire io_deq_bits_1_valid;
	output wire [63:0] io_deq_bits_1_pc;
	output wire [31:0] io_deq_bits_1_inst;
	output wire [5:0] io_deq_bits_1_fu_code;
	output wire [9:0] io_deq_bits_1_alu_op;
	output wire [1:0] io_deq_bits_1_op1_sel;
	output wire [2:0] io_deq_bits_1_op2_sel;
	output wire [63:0] io_deq_bits_1_imm;
	output wire [2:0] io_deq_bits_1_imm_sel;
	output wire io_deq_bits_1_is_w;
	output wire [2:0] io_deq_bits_1_mem_cmd;
	output wire [1:0] io_deq_bits_1_mem_size;
	output wire io_deq_bits_1_mem_signed;
	output wire [3:0] io_deq_bits_1_br_type;
	output wire [4:0] io_deq_bits_1_l_rd;
	output wire [4:0] io_deq_bits_1_l_rs1;
	output wire [4:0] io_deq_bits_1_l_rs2;
	output wire io_deq_bits_1_rf_wen;
	output wire io_deq_bits_1_use_rs1;
	output wire io_deq_bits_1_use_rs2;
	output wire io_deq_bits_1_exception;
	output wire io_deq_bits_1_pred_taken;
	output wire [63:0] io_deq_bits_1_pred_target;
	wire _uop_decoded_T_1 = io_enq_bits_0_inst[6:0] == 7'h37;
	wire _uop_decoded_T_3 = io_enq_bits_0_inst[6:0] == 7'h17;
	wire _uop_decoded_T_5 = io_enq_bits_0_inst[6:0] == 7'h6f;
	wire [9:0] _GEN = {io_enq_bits_0_inst[14:12], io_enq_bits_0_inst[6:0]};
	wire _uop_decoded_T_7 = _GEN == 10'h067;
	wire _uop_decoded_T_9 = _GEN == 10'h063;
	wire _uop_decoded_T_11 = _GEN == 10'h0e3;
	wire _uop_decoded_T_13 = _GEN == 10'h263;
	wire _uop_decoded_T_15 = _GEN == 10'h2e3;
	wire _uop_decoded_T_17 = _GEN == 10'h363;
	wire _uop_decoded_T_19 = _GEN == 10'h3e3;
	wire _uop_decoded_T_21 = _GEN == 10'h003;
	wire _uop_decoded_T_23 = _GEN == 10'h083;
	wire _uop_decoded_T_25 = _GEN == 10'h103;
	wire _uop_decoded_T_661 = _GEN == 10'h183;
	wire _uop_decoded_T_29 = _GEN == 10'h203;
	wire _uop_decoded_T_31 = _GEN == 10'h283;
	wire _uop_decoded_T_33 = _GEN == 10'h303;
	wire _uop_decoded_T_35 = _GEN == 10'h023;
	wire _uop_decoded_T_37 = _GEN == 10'h0a3;
	wire _uop_decoded_T_39 = _GEN == 10'h123;
	wire _uop_decoded_T_41 = _GEN == 10'h1a3;
	wire _uop_decoded_T_43 = _GEN == 10'h013;
	wire _uop_decoded_T_45 = _GEN == 10'h113;
	wire _uop_decoded_T_47 = _GEN == 10'h193;
	wire _uop_decoded_T_49 = _GEN == 10'h213;
	wire _uop_decoded_T_51 = _GEN == 10'h313;
	wire _uop_decoded_T_53 = _GEN == 10'h393;
	wire [15:0] _GEN_0 = {io_enq_bits_0_inst[31:26], io_enq_bits_0_inst[14:12], io_enq_bits_0_inst[6:0]};
	wire _uop_decoded_T_55 = _GEN_0 == 16'h0093;
	wire _uop_decoded_T_57 = _GEN_0 == 16'h0293;
	wire _uop_decoded_T_59 = _GEN_0 == 16'h4293;
	wire [16:0] _GEN_1 = {io_enq_bits_0_inst[31:25], io_enq_bits_0_inst[14:12], io_enq_bits_0_inst[6:0]};
	wire _uop_decoded_T_61 = _GEN_1 == 17'h00033;
	wire _uop_decoded_T_63 = _GEN_1 == 17'h08033;
	wire _uop_decoded_T_65 = _GEN_1 == 17'h000b3;
	wire _uop_decoded_T_67 = _GEN_1 == 17'h00133;
	wire _uop_decoded_T_69 = _GEN_1 == 17'h001b3;
	wire _uop_decoded_T_71 = _GEN_1 == 17'h00233;
	wire _uop_decoded_T_73 = _GEN_1 == 17'h002b3;
	wire _uop_decoded_T_75 = _GEN_1 == 17'h082b3;
	wire _uop_decoded_T_77 = _GEN_1 == 17'h00333;
	wire _uop_decoded_T_79 = _GEN_1 == 17'h003b3;
	wire _uop_decoded_T_81 = _GEN == 10'h01b;
	wire _uop_decoded_T_83 = _GEN_1 == 17'h0009b;
	wire _uop_decoded_T_85 = _GEN_1 == 17'h0029b;
	wire _uop_decoded_T_87 = _GEN_1 == 17'h0829b;
	wire _uop_decoded_T_89 = _GEN_1 == 17'h0003b;
	wire _uop_decoded_T_91 = _GEN_1 == 17'h0803b;
	wire _uop_decoded_T_93 = _GEN_1 == 17'h000bb;
	wire _uop_decoded_T_95 = _GEN_1 == 17'h002bb;
	wire _uop_decoded_T_674 = _GEN_1 == 17'h082bb;
	wire _GEN_2 = ((_uop_decoded_T_89 | _uop_decoded_T_91) | _uop_decoded_T_93) | _uop_decoded_T_95;
	wire _GEN_3 = (((_uop_decoded_T_81 | _uop_decoded_T_83) | _uop_decoded_T_85) | _uop_decoded_T_87) | _GEN_2;
	wire _GEN_4 = ((((((((((((((((((_uop_decoded_T_43 | _uop_decoded_T_45) | _uop_decoded_T_47) | _uop_decoded_T_49) | _uop_decoded_T_51) | _uop_decoded_T_53) | _uop_decoded_T_55) | _uop_decoded_T_57) | _uop_decoded_T_59) | _uop_decoded_T_61) | _uop_decoded_T_63) | _uop_decoded_T_65) | _uop_decoded_T_67) | _uop_decoded_T_69) | _uop_decoded_T_71) | _uop_decoded_T_73) | _uop_decoded_T_75) | _uop_decoded_T_77) | _uop_decoded_T_79) | _GEN_3;
	wire _GEN_5 = (((((((((((((((((_uop_decoded_T_7 | _uop_decoded_T_9) | _uop_decoded_T_11) | _uop_decoded_T_13) | _uop_decoded_T_15) | _uop_decoded_T_17) | _uop_decoded_T_19) | _uop_decoded_T_21) | _uop_decoded_T_23) | _uop_decoded_T_25) | _uop_decoded_T_661) | _uop_decoded_T_29) | _uop_decoded_T_31) | _uop_decoded_T_33) | _uop_decoded_T_35) | _uop_decoded_T_37) | _uop_decoded_T_39) | _uop_decoded_T_41) | _GEN_4;
	wire uop_decoded_0 = (((_uop_decoded_T_1 | _uop_decoded_T_3) | _uop_decoded_T_5) | _GEN_5) | _uop_decoded_T_674;
	wire _GEN_6 = ((_uop_decoded_T_35 | _uop_decoded_T_37) | _uop_decoded_T_39) | _uop_decoded_T_41;
	wire _GEN_7 = ((((_uop_decoded_T_9 | _uop_decoded_T_11) | _uop_decoded_T_13) | _uop_decoded_T_15) | _uop_decoded_T_17) | _uop_decoded_T_19;
	wire _GEN_8 = ((_uop_decoded_T_1 | _uop_decoded_T_3) | _uop_decoded_T_5) | _uop_decoded_T_7;
	wire _GEN_9 = _uop_decoded_T_3 | _uop_decoded_T_5;
	wire _GEN_10 = ((_uop_decoded_T_81 | _uop_decoded_T_83) | _uop_decoded_T_85) | _uop_decoded_T_87;
	wire _GEN_11 = ((((((((_uop_decoded_T_61 | _uop_decoded_T_63) | _uop_decoded_T_65) | _uop_decoded_T_67) | _uop_decoded_T_69) | _uop_decoded_T_71) | _uop_decoded_T_73) | _uop_decoded_T_75) | _uop_decoded_T_77) | _uop_decoded_T_79;
	wire _GEN_12 = (((((((_uop_decoded_T_43 | _uop_decoded_T_45) | _uop_decoded_T_47) | _uop_decoded_T_49) | _uop_decoded_T_51) | _uop_decoded_T_53) | _uop_decoded_T_55) | _uop_decoded_T_57) | _uop_decoded_T_59;
	wire _GEN_13 = (((((_uop_decoded_T_21 | _uop_decoded_T_23) | _uop_decoded_T_25) | _uop_decoded_T_661) | _uop_decoded_T_29) | _uop_decoded_T_31) | _uop_decoded_T_33;
	wire uop_decoded_5 = _GEN_8 | (~_GEN_7 & (_GEN_13 | (~_GEN_6 & (_GEN_4 | _uop_decoded_T_674))));
	wire uop_decoded_6 = ~(_uop_decoded_T_1 | _GEN_9) & (_GEN_5 | _uop_decoded_T_674);
	wire uop_decoded_7 = ~_GEN_8 & (_GEN_7 | (~_GEN_13 & (_GEN_6 | (~_GEN_12 & (_GEN_11 | (~_GEN_10 & (_GEN_2 | _uop_decoded_T_674)))))));
	wire [2:0] uop_decoded_8 = (_uop_decoded_T_1 | _uop_decoded_T_3 ? 3'h3 : (_uop_decoded_T_5 ? 3'h4 : (_uop_decoded_T_7 ? 3'h0 : (_GEN_7 ? 3'h2 : (_GEN_13 ? 3'h0 : (_GEN_6 ? 3'h1 : (_GEN_12 | ~(_GEN_11 | ~_GEN_10) ? 3'h0 : 3'h5)))))));
	wire _GEN_14 = (((_uop_decoded_T_1 | _uop_decoded_T_3) | _uop_decoded_T_5) | _uop_decoded_T_7) | _GEN_7;
	wire [511:0] _GEN_15 = {192'h000000000000000000000000000000000000000000000000, {44 {io_enq_bits_0_inst[31]}}, io_enq_bits_0_inst[19:12], io_enq_bits_0_inst[20], io_enq_bits_0_inst[30:21], 1'h0, {32 {io_enq_bits_0_inst[31]}}, io_enq_bits_0_inst[31:12], 12'h000, {52 {io_enq_bits_0_inst[31]}}, io_enq_bits_0_inst[7], io_enq_bits_0_inst[30:25], io_enq_bits_0_inst[11:8], 1'h0, {52 {io_enq_bits_0_inst[31]}}, io_enq_bits_0_inst[31:25], io_enq_bits_0_inst[11:7], {52 {io_enq_bits_0_inst[31]}}, io_enq_bits_0_inst[31:20]};
	wire _uop_decoded_T_723 = io_enq_bits_1_inst[6:0] == 7'h37;
	wire _uop_decoded_T_725 = io_enq_bits_1_inst[6:0] == 7'h17;
	wire _uop_decoded_T_727 = io_enq_bits_1_inst[6:0] == 7'h6f;
	wire [9:0] _GEN_16 = {io_enq_bits_1_inst[14:12], io_enq_bits_1_inst[6:0]};
	wire _uop_decoded_T_729 = _GEN_16 == 10'h067;
	wire _uop_decoded_T_731 = _GEN_16 == 10'h063;
	wire _uop_decoded_T_733 = _GEN_16 == 10'h0e3;
	wire _uop_decoded_T_735 = _GEN_16 == 10'h263;
	wire _uop_decoded_T_737 = _GEN_16 == 10'h2e3;
	wire _uop_decoded_T_739 = _GEN_16 == 10'h363;
	wire _uop_decoded_T_741 = _GEN_16 == 10'h3e3;
	wire _uop_decoded_T_743 = _GEN_16 == 10'h003;
	wire _uop_decoded_T_745 = _GEN_16 == 10'h083;
	wire _uop_decoded_T_747 = _GEN_16 == 10'h103;
	wire _uop_decoded_T_1383 = _GEN_16 == 10'h183;
	wire _uop_decoded_T_751 = _GEN_16 == 10'h203;
	wire _uop_decoded_T_753 = _GEN_16 == 10'h283;
	wire _uop_decoded_T_755 = _GEN_16 == 10'h303;
	wire _uop_decoded_T_757 = _GEN_16 == 10'h023;
	wire _uop_decoded_T_759 = _GEN_16 == 10'h0a3;
	wire _uop_decoded_T_761 = _GEN_16 == 10'h123;
	wire _uop_decoded_T_763 = _GEN_16 == 10'h1a3;
	wire _uop_decoded_T_765 = _GEN_16 == 10'h013;
	wire _uop_decoded_T_767 = _GEN_16 == 10'h113;
	wire _uop_decoded_T_769 = _GEN_16 == 10'h193;
	wire _uop_decoded_T_771 = _GEN_16 == 10'h213;
	wire _uop_decoded_T_773 = _GEN_16 == 10'h313;
	wire _uop_decoded_T_775 = _GEN_16 == 10'h393;
	wire [15:0] _GEN_17 = {io_enq_bits_1_inst[31:26], io_enq_bits_1_inst[14:12], io_enq_bits_1_inst[6:0]};
	wire _uop_decoded_T_777 = _GEN_17 == 16'h0093;
	wire _uop_decoded_T_779 = _GEN_17 == 16'h0293;
	wire _uop_decoded_T_781 = _GEN_17 == 16'h4293;
	wire [16:0] _GEN_18 = {io_enq_bits_1_inst[31:25], io_enq_bits_1_inst[14:12], io_enq_bits_1_inst[6:0]};
	wire _uop_decoded_T_783 = _GEN_18 == 17'h00033;
	wire _uop_decoded_T_785 = _GEN_18 == 17'h08033;
	wire _uop_decoded_T_787 = _GEN_18 == 17'h000b3;
	wire _uop_decoded_T_789 = _GEN_18 == 17'h00133;
	wire _uop_decoded_T_791 = _GEN_18 == 17'h001b3;
	wire _uop_decoded_T_793 = _GEN_18 == 17'h00233;
	wire _uop_decoded_T_795 = _GEN_18 == 17'h002b3;
	wire _uop_decoded_T_797 = _GEN_18 == 17'h082b3;
	wire _uop_decoded_T_799 = _GEN_18 == 17'h00333;
	wire _uop_decoded_T_801 = _GEN_18 == 17'h003b3;
	wire _uop_decoded_T_803 = _GEN_16 == 10'h01b;
	wire _uop_decoded_T_805 = _GEN_18 == 17'h0009b;
	wire _uop_decoded_T_807 = _GEN_18 == 17'h0029b;
	wire _uop_decoded_T_809 = _GEN_18 == 17'h0829b;
	wire _uop_decoded_T_811 = _GEN_18 == 17'h0003b;
	wire _uop_decoded_T_813 = _GEN_18 == 17'h0803b;
	wire _uop_decoded_T_815 = _GEN_18 == 17'h000bb;
	wire _uop_decoded_T_817 = _GEN_18 == 17'h002bb;
	wire _uop_decoded_T_1396 = _GEN_18 == 17'h082bb;
	wire _GEN_19 = ((_uop_decoded_T_811 | _uop_decoded_T_813) | _uop_decoded_T_815) | _uop_decoded_T_817;
	wire _GEN_20 = (((_uop_decoded_T_803 | _uop_decoded_T_805) | _uop_decoded_T_807) | _uop_decoded_T_809) | _GEN_19;
	wire _GEN_21 = ((((((((((((((((((_uop_decoded_T_765 | _uop_decoded_T_767) | _uop_decoded_T_769) | _uop_decoded_T_771) | _uop_decoded_T_773) | _uop_decoded_T_775) | _uop_decoded_T_777) | _uop_decoded_T_779) | _uop_decoded_T_781) | _uop_decoded_T_783) | _uop_decoded_T_785) | _uop_decoded_T_787) | _uop_decoded_T_789) | _uop_decoded_T_791) | _uop_decoded_T_793) | _uop_decoded_T_795) | _uop_decoded_T_797) | _uop_decoded_T_799) | _uop_decoded_T_801) | _GEN_20;
	wire _GEN_22 = (((((((((((((((((_uop_decoded_T_729 | _uop_decoded_T_731) | _uop_decoded_T_733) | _uop_decoded_T_735) | _uop_decoded_T_737) | _uop_decoded_T_739) | _uop_decoded_T_741) | _uop_decoded_T_743) | _uop_decoded_T_745) | _uop_decoded_T_747) | _uop_decoded_T_1383) | _uop_decoded_T_751) | _uop_decoded_T_753) | _uop_decoded_T_755) | _uop_decoded_T_757) | _uop_decoded_T_759) | _uop_decoded_T_761) | _uop_decoded_T_763) | _GEN_21;
	wire uop_decoded_0_1 = (((_uop_decoded_T_723 | _uop_decoded_T_725) | _uop_decoded_T_727) | _GEN_22) | _uop_decoded_T_1396;
	wire _GEN_23 = ((_uop_decoded_T_757 | _uop_decoded_T_759) | _uop_decoded_T_761) | _uop_decoded_T_763;
	wire _GEN_24 = ((((_uop_decoded_T_731 | _uop_decoded_T_733) | _uop_decoded_T_735) | _uop_decoded_T_737) | _uop_decoded_T_739) | _uop_decoded_T_741;
	wire _GEN_25 = ((_uop_decoded_T_723 | _uop_decoded_T_725) | _uop_decoded_T_727) | _uop_decoded_T_729;
	wire _GEN_26 = _uop_decoded_T_725 | _uop_decoded_T_727;
	wire _GEN_27 = ((_uop_decoded_T_803 | _uop_decoded_T_805) | _uop_decoded_T_807) | _uop_decoded_T_809;
	wire _GEN_28 = ((((((((_uop_decoded_T_783 | _uop_decoded_T_785) | _uop_decoded_T_787) | _uop_decoded_T_789) | _uop_decoded_T_791) | _uop_decoded_T_793) | _uop_decoded_T_795) | _uop_decoded_T_797) | _uop_decoded_T_799) | _uop_decoded_T_801;
	wire _GEN_29 = (((((((_uop_decoded_T_765 | _uop_decoded_T_767) | _uop_decoded_T_769) | _uop_decoded_T_771) | _uop_decoded_T_773) | _uop_decoded_T_775) | _uop_decoded_T_777) | _uop_decoded_T_779) | _uop_decoded_T_781;
	wire _GEN_30 = (((((_uop_decoded_T_743 | _uop_decoded_T_745) | _uop_decoded_T_747) | _uop_decoded_T_1383) | _uop_decoded_T_751) | _uop_decoded_T_753) | _uop_decoded_T_755;
	wire uop_decoded_5_1 = _GEN_25 | (~_GEN_24 & (_GEN_30 | (~_GEN_23 & (_GEN_21 | _uop_decoded_T_1396))));
	wire uop_decoded_6_1 = ~(_uop_decoded_T_723 | _GEN_26) & (_GEN_22 | _uop_decoded_T_1396);
	wire uop_decoded_7_1 = ~_GEN_25 & (_GEN_24 | (~_GEN_30 & (_GEN_23 | (~_GEN_29 & (_GEN_28 | (~_GEN_27 & (_GEN_19 | _uop_decoded_T_1396)))))));
	wire [2:0] uop_decoded_8_1 = (_uop_decoded_T_723 | _uop_decoded_T_725 ? 3'h3 : (_uop_decoded_T_727 ? 3'h4 : (_uop_decoded_T_729 ? 3'h0 : (_GEN_24 ? 3'h2 : (_GEN_30 ? 3'h0 : (_GEN_23 ? 3'h1 : (_GEN_29 | ~(_GEN_28 | ~_GEN_27) ? 3'h0 : 3'h5)))))));
	wire _GEN_31 = (((_uop_decoded_T_723 | _uop_decoded_T_725) | _uop_decoded_T_727) | _uop_decoded_T_729) | _GEN_24;
	wire [511:0] _GEN_32 = {192'h000000000000000000000000000000000000000000000000, {44 {io_enq_bits_1_inst[31]}}, io_enq_bits_1_inst[19:12], io_enq_bits_1_inst[20], io_enq_bits_1_inst[30:21], 1'h0, {32 {io_enq_bits_1_inst[31]}}, io_enq_bits_1_inst[31:12], 12'h000, {52 {io_enq_bits_1_inst[31]}}, io_enq_bits_1_inst[7], io_enq_bits_1_inst[30:25], io_enq_bits_1_inst[11:8], 1'h0, {52 {io_enq_bits_1_inst[31]}}, io_enq_bits_1_inst[31:25], io_enq_bits_1_inst[11:7], {52 {io_enq_bits_1_inst[31]}}, io_enq_bits_1_inst[31:20]};
	assign io_enq_ready = io_deq_ready;
	assign io_deq_valid = io_enq_valid;
	assign io_deq_bits_0_valid = uop_decoded_0 & io_enq_bits_0_valid;
	assign io_deq_bits_0_pc = io_enq_bits_0_pc;
	assign io_deq_bits_0_inst = io_enq_bits_0_inst;
	assign io_deq_bits_0_fu_code = (_GEN_8 ? 6'h00 : (_GEN_7 ? 6'h02 : {5'h00, ((((((_uop_decoded_T_21 | _uop_decoded_T_23) | _uop_decoded_T_25) | _uop_decoded_T_661) | _uop_decoded_T_29) | _uop_decoded_T_31) | _uop_decoded_T_33) | _GEN_6}));
	assign io_deq_bits_0_alu_op = (_GEN_8 ? 10'h000 : (_GEN_7 ? 10'h00a : (((((((((((_uop_decoded_T_21 | _uop_decoded_T_23) | _uop_decoded_T_25) | _uop_decoded_T_661) | _uop_decoded_T_29) | _uop_decoded_T_31) | _uop_decoded_T_33) | _uop_decoded_T_35) | _uop_decoded_T_37) | _uop_decoded_T_39) | _uop_decoded_T_41) | _uop_decoded_T_43 ? 10'h000 : (_uop_decoded_T_45 ? 10'h008 : (_uop_decoded_T_47 ? 10'h009 : (_uop_decoded_T_49 ? 10'h004 : (_uop_decoded_T_51 ? 10'h003 : (_uop_decoded_T_53 ? 10'h002 : (_uop_decoded_T_55 ? 10'h005 : (_uop_decoded_T_57 ? 10'h006 : (_uop_decoded_T_59 ? 10'h007 : (_uop_decoded_T_61 ? 10'h000 : (_uop_decoded_T_63 ? 10'h001 : (_uop_decoded_T_65 ? 10'h005 : (_uop_decoded_T_67 ? 10'h008 : (_uop_decoded_T_69 ? 10'h009 : (_uop_decoded_T_71 ? 10'h004 : (_uop_decoded_T_73 ? 10'h006 : (_uop_decoded_T_75 ? 10'h007 : (_uop_decoded_T_77 ? 10'h003 : (_uop_decoded_T_79 ? 10'h002 : (_uop_decoded_T_81 ? 10'h000 : (_uop_decoded_T_83 ? 10'h005 : (_uop_decoded_T_85 ? 10'h006 : (_uop_decoded_T_87 ? 10'h007 : (_uop_decoded_T_89 ? 10'h000 : (_uop_decoded_T_91 ? 10'h001 : (_uop_decoded_T_93 ? 10'h005 : (_uop_decoded_T_95 ? 10'h006 : (_uop_decoded_T_674 ? 10'h007 : 10'h000))))))))))))))))))))))))))))));
	assign io_deq_bits_0_op1_sel = (_uop_decoded_T_1 ? 2'h1 : {_GEN_9, 1'h0});
	assign io_deq_bits_0_op2_sel = (_GEN_8 ? 3'h2 : (_GEN_7 ? 3'h0 : (((((((((((_uop_decoded_T_21 | _uop_decoded_T_23) | _uop_decoded_T_25) | _uop_decoded_T_661) | _uop_decoded_T_29) | _uop_decoded_T_31) | _uop_decoded_T_33) | _uop_decoded_T_35) | _uop_decoded_T_37) | _uop_decoded_T_39) | _uop_decoded_T_41) | _GEN_12 ? 3'h2 : (_GEN_11 ? 3'h0 : {1'h0, _GEN_10, 1'h0}))));
	assign io_deq_bits_0_imm = _GEN_15[uop_decoded_8 * 64+:64];
	assign io_deq_bits_0_imm_sel = uop_decoded_8;
	assign io_deq_bits_0_is_w = ~((((((((((((((((((((((((((((((_uop_decoded_T_1 | _uop_decoded_T_3) | _uop_decoded_T_5) | _uop_decoded_T_7) | _uop_decoded_T_9) | _uop_decoded_T_11) | _uop_decoded_T_13) | _uop_decoded_T_15) | _uop_decoded_T_17) | _uop_decoded_T_19) | _uop_decoded_T_21) | _uop_decoded_T_23) | _uop_decoded_T_25) | _uop_decoded_T_661) | _uop_decoded_T_29) | _uop_decoded_T_31) | _uop_decoded_T_33) | _uop_decoded_T_35) | _uop_decoded_T_37) | _uop_decoded_T_39) | _uop_decoded_T_41) | _uop_decoded_T_43) | _uop_decoded_T_45) | _uop_decoded_T_47) | _uop_decoded_T_49) | _uop_decoded_T_51) | _uop_decoded_T_53) | _uop_decoded_T_55) | _uop_decoded_T_57) | _uop_decoded_T_59) | _GEN_11) & (_GEN_3 | _uop_decoded_T_674);
	assign io_deq_bits_0_mem_cmd = {1'h0, (_GEN_14 ? 2'h0 : (_GEN_13 ? 2'h1 : {_GEN_6, 1'h0}))};
	assign io_deq_bits_0_mem_size = (_GEN_14 ? 2'h0 : (_uop_decoded_T_21 ? 2'h1 : (_uop_decoded_T_23 ? 2'h2 : (_uop_decoded_T_25 ? 2'h3 : (_uop_decoded_T_661 ? 2'h0 : (_uop_decoded_T_29 ? 2'h1 : (_uop_decoded_T_31 ? 2'h2 : (_uop_decoded_T_33 ? 2'h3 : (_uop_decoded_T_35 ? 2'h1 : (_uop_decoded_T_37 ? 2'h2 : {2 {_uop_decoded_T_39}}))))))))));
	assign io_deq_bits_0_mem_signed = ~_GEN_14 & (((_uop_decoded_T_21 | _uop_decoded_T_23) | _uop_decoded_T_25) | _uop_decoded_T_661);
	assign io_deq_bits_0_br_type = {_GEN == 10'h067, (({_GEN == 10'h3e3, {_GEN == 10'h063, _GEN == 10'h0e3} | {2 {_GEN == 10'h2e3}}} | (_GEN == 10'h263 ? 3'h5 : 3'h0)) | (_GEN == 10'h363 ? 3'h6 : 3'h0)) | {3 {io_enq_bits_0_inst[6:0] == 7'h6f}}};
	assign io_deq_bits_0_l_rd = (uop_decoded_5 ? io_enq_bits_0_inst[11:7] : 5'h00);
	assign io_deq_bits_0_l_rs1 = (uop_decoded_6 ? io_enq_bits_0_inst[19:15] : 5'h00);
	assign io_deq_bits_0_l_rs2 = (uop_decoded_7 ? io_enq_bits_0_inst[24:20] : 5'h00);
	assign io_deq_bits_0_rf_wen = uop_decoded_5;
	assign io_deq_bits_0_use_rs1 = uop_decoded_6;
	assign io_deq_bits_0_use_rs2 = uop_decoded_7;
	assign io_deq_bits_0_exception = ~uop_decoded_0;
	assign io_deq_bits_0_pred_taken = io_enq_bits_0_pred_taken;
	assign io_deq_bits_0_pred_target = io_enq_bits_0_pred_target;
	assign io_deq_bits_1_valid = uop_decoded_0_1 & io_enq_bits_1_valid;
	assign io_deq_bits_1_pc = io_enq_bits_1_pc;
	assign io_deq_bits_1_inst = io_enq_bits_1_inst;
	assign io_deq_bits_1_fu_code = (_GEN_25 ? 6'h00 : (_GEN_24 ? 6'h02 : {5'h00, ((((((_uop_decoded_T_743 | _uop_decoded_T_745) | _uop_decoded_T_747) | _uop_decoded_T_1383) | _uop_decoded_T_751) | _uop_decoded_T_753) | _uop_decoded_T_755) | _GEN_23}));
	assign io_deq_bits_1_alu_op = (_GEN_25 ? 10'h000 : (_GEN_24 ? 10'h00a : (((((((((((_uop_decoded_T_743 | _uop_decoded_T_745) | _uop_decoded_T_747) | _uop_decoded_T_1383) | _uop_decoded_T_751) | _uop_decoded_T_753) | _uop_decoded_T_755) | _uop_decoded_T_757) | _uop_decoded_T_759) | _uop_decoded_T_761) | _uop_decoded_T_763) | _uop_decoded_T_765 ? 10'h000 : (_uop_decoded_T_767 ? 10'h008 : (_uop_decoded_T_769 ? 10'h009 : (_uop_decoded_T_771 ? 10'h004 : (_uop_decoded_T_773 ? 10'h003 : (_uop_decoded_T_775 ? 10'h002 : (_uop_decoded_T_777 ? 10'h005 : (_uop_decoded_T_779 ? 10'h006 : (_uop_decoded_T_781 ? 10'h007 : (_uop_decoded_T_783 ? 10'h000 : (_uop_decoded_T_785 ? 10'h001 : (_uop_decoded_T_787 ? 10'h005 : (_uop_decoded_T_789 ? 10'h008 : (_uop_decoded_T_791 ? 10'h009 : (_uop_decoded_T_793 ? 10'h004 : (_uop_decoded_T_795 ? 10'h006 : (_uop_decoded_T_797 ? 10'h007 : (_uop_decoded_T_799 ? 10'h003 : (_uop_decoded_T_801 ? 10'h002 : (_uop_decoded_T_803 ? 10'h000 : (_uop_decoded_T_805 ? 10'h005 : (_uop_decoded_T_807 ? 10'h006 : (_uop_decoded_T_809 ? 10'h007 : (_uop_decoded_T_811 ? 10'h000 : (_uop_decoded_T_813 ? 10'h001 : (_uop_decoded_T_815 ? 10'h005 : (_uop_decoded_T_817 ? 10'h006 : (_uop_decoded_T_1396 ? 10'h007 : 10'h000))))))))))))))))))))))))))))));
	assign io_deq_bits_1_op1_sel = (_uop_decoded_T_723 ? 2'h1 : {_GEN_26, 1'h0});
	assign io_deq_bits_1_op2_sel = (_GEN_25 ? 3'h2 : (_GEN_24 ? 3'h0 : (((((((((((_uop_decoded_T_743 | _uop_decoded_T_745) | _uop_decoded_T_747) | _uop_decoded_T_1383) | _uop_decoded_T_751) | _uop_decoded_T_753) | _uop_decoded_T_755) | _uop_decoded_T_757) | _uop_decoded_T_759) | _uop_decoded_T_761) | _uop_decoded_T_763) | _GEN_29 ? 3'h2 : (_GEN_28 ? 3'h0 : {1'h0, _GEN_27, 1'h0}))));
	assign io_deq_bits_1_imm = _GEN_32[uop_decoded_8_1 * 64+:64];
	assign io_deq_bits_1_imm_sel = uop_decoded_8_1;
	assign io_deq_bits_1_is_w = ~((((((((((((((((((((((((((((((_uop_decoded_T_723 | _uop_decoded_T_725) | _uop_decoded_T_727) | _uop_decoded_T_729) | _uop_decoded_T_731) | _uop_decoded_T_733) | _uop_decoded_T_735) | _uop_decoded_T_737) | _uop_decoded_T_739) | _uop_decoded_T_741) | _uop_decoded_T_743) | _uop_decoded_T_745) | _uop_decoded_T_747) | _uop_decoded_T_1383) | _uop_decoded_T_751) | _uop_decoded_T_753) | _uop_decoded_T_755) | _uop_decoded_T_757) | _uop_decoded_T_759) | _uop_decoded_T_761) | _uop_decoded_T_763) | _uop_decoded_T_765) | _uop_decoded_T_767) | _uop_decoded_T_769) | _uop_decoded_T_771) | _uop_decoded_T_773) | _uop_decoded_T_775) | _uop_decoded_T_777) | _uop_decoded_T_779) | _uop_decoded_T_781) | _GEN_28) & (_GEN_20 | _uop_decoded_T_1396);
	assign io_deq_bits_1_mem_cmd = {1'h0, (_GEN_31 ? 2'h0 : (_GEN_30 ? 2'h1 : {_GEN_23, 1'h0}))};
	assign io_deq_bits_1_mem_size = (_GEN_31 ? 2'h0 : (_uop_decoded_T_743 ? 2'h1 : (_uop_decoded_T_745 ? 2'h2 : (_uop_decoded_T_747 ? 2'h3 : (_uop_decoded_T_1383 ? 2'h0 : (_uop_decoded_T_751 ? 2'h1 : (_uop_decoded_T_753 ? 2'h2 : (_uop_decoded_T_755 ? 2'h3 : (_uop_decoded_T_757 ? 2'h1 : (_uop_decoded_T_759 ? 2'h2 : {2 {_uop_decoded_T_761}}))))))))));
	assign io_deq_bits_1_mem_signed = ~_GEN_31 & (((_uop_decoded_T_743 | _uop_decoded_T_745) | _uop_decoded_T_747) | _uop_decoded_T_1383);
	assign io_deq_bits_1_br_type = {_GEN_16 == 10'h067, (({_GEN_16 == 10'h3e3, {_GEN_16 == 10'h063, _GEN_16 == 10'h0e3} | {2 {_GEN_16 == 10'h2e3}}} | (_GEN_16 == 10'h263 ? 3'h5 : 3'h0)) | (_GEN_16 == 10'h363 ? 3'h6 : 3'h0)) | {3 {io_enq_bits_1_inst[6:0] == 7'h6f}}};
	assign io_deq_bits_1_l_rd = (uop_decoded_5_1 ? io_enq_bits_1_inst[11:7] : 5'h00);
	assign io_deq_bits_1_l_rs1 = (uop_decoded_6_1 ? io_enq_bits_1_inst[19:15] : 5'h00);
	assign io_deq_bits_1_l_rs2 = (uop_decoded_7_1 ? io_enq_bits_1_inst[24:20] : 5'h00);
	assign io_deq_bits_1_rf_wen = uop_decoded_5_1;
	assign io_deq_bits_1_use_rs1 = uop_decoded_6_1;
	assign io_deq_bits_1_use_rs2 = uop_decoded_7_1;
	assign io_deq_bits_1_exception = ~uop_decoded_0_1;
	assign io_deq_bits_1_pred_taken = io_enq_bits_1_pred_taken;
	assign io_deq_bits_1_pred_target = io_enq_bits_1_pred_target;
endmodule
module RenameUnit (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_0_valid,
	io_enq_bits_0_pc,
	io_enq_bits_0_inst,
	io_enq_bits_0_fu_code,
	io_enq_bits_0_alu_op,
	io_enq_bits_0_op1_sel,
	io_enq_bits_0_op2_sel,
	io_enq_bits_0_imm,
	io_enq_bits_0_imm_sel,
	io_enq_bits_0_is_w,
	io_enq_bits_0_mem_cmd,
	io_enq_bits_0_mem_size,
	io_enq_bits_0_mem_signed,
	io_enq_bits_0_br_type,
	io_enq_bits_0_l_rd,
	io_enq_bits_0_l_rs1,
	io_enq_bits_0_l_rs2,
	io_enq_bits_0_rf_wen,
	io_enq_bits_0_use_rs1,
	io_enq_bits_0_use_rs2,
	io_enq_bits_0_exception,
	io_enq_bits_0_pred_taken,
	io_enq_bits_0_pred_target,
	io_enq_bits_1_valid,
	io_enq_bits_1_pc,
	io_enq_bits_1_inst,
	io_enq_bits_1_fu_code,
	io_enq_bits_1_alu_op,
	io_enq_bits_1_op1_sel,
	io_enq_bits_1_op2_sel,
	io_enq_bits_1_imm,
	io_enq_bits_1_imm_sel,
	io_enq_bits_1_is_w,
	io_enq_bits_1_mem_cmd,
	io_enq_bits_1_mem_size,
	io_enq_bits_1_mem_signed,
	io_enq_bits_1_br_type,
	io_enq_bits_1_l_rd,
	io_enq_bits_1_l_rs1,
	io_enq_bits_1_l_rs2,
	io_enq_bits_1_rf_wen,
	io_enq_bits_1_use_rs1,
	io_enq_bits_1_use_rs2,
	io_enq_bits_1_exception,
	io_enq_bits_1_pred_taken,
	io_enq_bits_1_pred_target,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_0_valid,
	io_deq_bits_0_pc,
	io_deq_bits_0_inst,
	io_deq_bits_0_fu_code,
	io_deq_bits_0_alu_op,
	io_deq_bits_0_op1_sel,
	io_deq_bits_0_op2_sel,
	io_deq_bits_0_imm,
	io_deq_bits_0_imm_sel,
	io_deq_bits_0_is_w,
	io_deq_bits_0_mem_cmd,
	io_deq_bits_0_mem_size,
	io_deq_bits_0_mem_signed,
	io_deq_bits_0_br_type,
	io_deq_bits_0_l_rd,
	io_deq_bits_0_l_rs1,
	io_deq_bits_0_l_rs2,
	io_deq_bits_0_rf_wen,
	io_deq_bits_0_use_rs1,
	io_deq_bits_0_use_rs2,
	io_deq_bits_0_p_rd,
	io_deq_bits_0_p_rs1,
	io_deq_bits_0_p_rs2,
	io_deq_bits_0_prs1_ready,
	io_deq_bits_0_prs2_ready,
	io_deq_bits_0_stale_p_rd,
	io_deq_bits_0_exception,
	io_deq_bits_0_pred_taken,
	io_deq_bits_0_pred_target,
	io_deq_bits_1_valid,
	io_deq_bits_1_pc,
	io_deq_bits_1_inst,
	io_deq_bits_1_fu_code,
	io_deq_bits_1_alu_op,
	io_deq_bits_1_op1_sel,
	io_deq_bits_1_op2_sel,
	io_deq_bits_1_imm,
	io_deq_bits_1_imm_sel,
	io_deq_bits_1_is_w,
	io_deq_bits_1_mem_cmd,
	io_deq_bits_1_mem_size,
	io_deq_bits_1_mem_signed,
	io_deq_bits_1_br_type,
	io_deq_bits_1_l_rd,
	io_deq_bits_1_l_rs1,
	io_deq_bits_1_l_rs2,
	io_deq_bits_1_rf_wen,
	io_deq_bits_1_use_rs1,
	io_deq_bits_1_use_rs2,
	io_deq_bits_1_p_rd,
	io_deq_bits_1_p_rs1,
	io_deq_bits_1_p_rs2,
	io_deq_bits_1_prs1_ready,
	io_deq_bits_1_prs2_ready,
	io_deq_bits_1_stale_p_rd,
	io_deq_bits_1_exception,
	io_deq_bits_1_pred_taken,
	io_deq_bits_1_pred_target,
	io_commit_free_0_valid,
	io_commit_free_0_bits,
	io_commit_free_1_valid,
	io_commit_free_1_bits,
	io_cdb_0_valid,
	io_cdb_0_bits_p_rd,
	io_cdb_1_valid,
	io_cdb_1_bits_p_rd,
	io_rbk_active,
	io_rbk_valid,
	io_rbk_l_rd,
	io_rbk_p_rd,
	io_rbk_stale_p_rd
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_enq_bits_0_valid;
	input [63:0] io_enq_bits_0_pc;
	input [31:0] io_enq_bits_0_inst;
	input [5:0] io_enq_bits_0_fu_code;
	input [9:0] io_enq_bits_0_alu_op;
	input [1:0] io_enq_bits_0_op1_sel;
	input [2:0] io_enq_bits_0_op2_sel;
	input [63:0] io_enq_bits_0_imm;
	input [2:0] io_enq_bits_0_imm_sel;
	input io_enq_bits_0_is_w;
	input [2:0] io_enq_bits_0_mem_cmd;
	input [1:0] io_enq_bits_0_mem_size;
	input io_enq_bits_0_mem_signed;
	input [3:0] io_enq_bits_0_br_type;
	input [4:0] io_enq_bits_0_l_rd;
	input [4:0] io_enq_bits_0_l_rs1;
	input [4:0] io_enq_bits_0_l_rs2;
	input io_enq_bits_0_rf_wen;
	input io_enq_bits_0_use_rs1;
	input io_enq_bits_0_use_rs2;
	input io_enq_bits_0_exception;
	input io_enq_bits_0_pred_taken;
	input [63:0] io_enq_bits_0_pred_target;
	input io_enq_bits_1_valid;
	input [63:0] io_enq_bits_1_pc;
	input [31:0] io_enq_bits_1_inst;
	input [5:0] io_enq_bits_1_fu_code;
	input [9:0] io_enq_bits_1_alu_op;
	input [1:0] io_enq_bits_1_op1_sel;
	input [2:0] io_enq_bits_1_op2_sel;
	input [63:0] io_enq_bits_1_imm;
	input [2:0] io_enq_bits_1_imm_sel;
	input io_enq_bits_1_is_w;
	input [2:0] io_enq_bits_1_mem_cmd;
	input [1:0] io_enq_bits_1_mem_size;
	input io_enq_bits_1_mem_signed;
	input [3:0] io_enq_bits_1_br_type;
	input [4:0] io_enq_bits_1_l_rd;
	input [4:0] io_enq_bits_1_l_rs1;
	input [4:0] io_enq_bits_1_l_rs2;
	input io_enq_bits_1_rf_wen;
	input io_enq_bits_1_use_rs1;
	input io_enq_bits_1_use_rs2;
	input io_enq_bits_1_exception;
	input io_enq_bits_1_pred_taken;
	input [63:0] io_enq_bits_1_pred_target;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire io_deq_bits_0_valid;
	output wire [63:0] io_deq_bits_0_pc;
	output wire [31:0] io_deq_bits_0_inst;
	output wire [5:0] io_deq_bits_0_fu_code;
	output wire [9:0] io_deq_bits_0_alu_op;
	output wire [1:0] io_deq_bits_0_op1_sel;
	output wire [2:0] io_deq_bits_0_op2_sel;
	output wire [63:0] io_deq_bits_0_imm;
	output wire [2:0] io_deq_bits_0_imm_sel;
	output wire io_deq_bits_0_is_w;
	output wire [2:0] io_deq_bits_0_mem_cmd;
	output wire [1:0] io_deq_bits_0_mem_size;
	output wire io_deq_bits_0_mem_signed;
	output wire [3:0] io_deq_bits_0_br_type;
	output wire [4:0] io_deq_bits_0_l_rd;
	output wire [4:0] io_deq_bits_0_l_rs1;
	output wire [4:0] io_deq_bits_0_l_rs2;
	output wire io_deq_bits_0_rf_wen;
	output wire io_deq_bits_0_use_rs1;
	output wire io_deq_bits_0_use_rs2;
	output wire [5:0] io_deq_bits_0_p_rd;
	output wire [5:0] io_deq_bits_0_p_rs1;
	output wire [5:0] io_deq_bits_0_p_rs2;
	output wire io_deq_bits_0_prs1_ready;
	output wire io_deq_bits_0_prs2_ready;
	output wire [5:0] io_deq_bits_0_stale_p_rd;
	output wire io_deq_bits_0_exception;
	output wire io_deq_bits_0_pred_taken;
	output wire [63:0] io_deq_bits_0_pred_target;
	output wire io_deq_bits_1_valid;
	output wire [63:0] io_deq_bits_1_pc;
	output wire [31:0] io_deq_bits_1_inst;
	output wire [5:0] io_deq_bits_1_fu_code;
	output wire [9:0] io_deq_bits_1_alu_op;
	output wire [1:0] io_deq_bits_1_op1_sel;
	output wire [2:0] io_deq_bits_1_op2_sel;
	output wire [63:0] io_deq_bits_1_imm;
	output wire [2:0] io_deq_bits_1_imm_sel;
	output wire io_deq_bits_1_is_w;
	output wire [2:0] io_deq_bits_1_mem_cmd;
	output wire [1:0] io_deq_bits_1_mem_size;
	output wire io_deq_bits_1_mem_signed;
	output wire [3:0] io_deq_bits_1_br_type;
	output wire [4:0] io_deq_bits_1_l_rd;
	output wire [4:0] io_deq_bits_1_l_rs1;
	output wire [4:0] io_deq_bits_1_l_rs2;
	output wire io_deq_bits_1_rf_wen;
	output wire io_deq_bits_1_use_rs1;
	output wire io_deq_bits_1_use_rs2;
	output wire [5:0] io_deq_bits_1_p_rd;
	output wire [5:0] io_deq_bits_1_p_rs1;
	output wire [5:0] io_deq_bits_1_p_rs2;
	output wire io_deq_bits_1_prs1_ready;
	output wire io_deq_bits_1_prs2_ready;
	output wire [5:0] io_deq_bits_1_stale_p_rd;
	output wire io_deq_bits_1_exception;
	output wire io_deq_bits_1_pred_taken;
	output wire [63:0] io_deq_bits_1_pred_target;
	input io_commit_free_0_valid;
	input [5:0] io_commit_free_0_bits;
	input io_commit_free_1_valid;
	input [5:0] io_commit_free_1_bits;
	input io_cdb_0_valid;
	input [5:0] io_cdb_0_bits_p_rd;
	input io_cdb_1_valid;
	input [5:0] io_cdb_1_bits_p_rd;
	input io_rbk_active;
	input io_rbk_valid;
	input [4:0] io_rbk_l_rd;
	input [5:0] io_rbk_p_rd;
	input [5:0] io_rbk_stale_p_rd;
	reg [5:0] rat_0;
	reg [5:0] rat_1;
	reg [5:0] rat_2;
	reg [5:0] rat_3;
	reg [5:0] rat_4;
	reg [5:0] rat_5;
	reg [5:0] rat_6;
	reg [5:0] rat_7;
	reg [5:0] rat_8;
	reg [5:0] rat_9;
	reg [5:0] rat_10;
	reg [5:0] rat_11;
	reg [5:0] rat_12;
	reg [5:0] rat_13;
	reg [5:0] rat_14;
	reg [5:0] rat_15;
	reg [5:0] rat_16;
	reg [5:0] rat_17;
	reg [5:0] rat_18;
	reg [5:0] rat_19;
	reg [5:0] rat_20;
	reg [5:0] rat_21;
	reg [5:0] rat_22;
	reg [5:0] rat_23;
	reg [5:0] rat_24;
	reg [5:0] rat_25;
	reg [5:0] rat_26;
	reg [5:0] rat_27;
	reg [5:0] rat_28;
	reg [5:0] rat_29;
	reg [5:0] rat_30;
	reg [5:0] rat_31;
	reg busy_table_1;
	reg busy_table_2;
	reg busy_table_3;
	reg busy_table_4;
	reg busy_table_5;
	reg busy_table_6;
	reg busy_table_7;
	reg busy_table_8;
	reg busy_table_9;
	reg busy_table_10;
	reg busy_table_11;
	reg busy_table_12;
	reg busy_table_13;
	reg busy_table_14;
	reg busy_table_15;
	reg busy_table_16;
	reg busy_table_17;
	reg busy_table_18;
	reg busy_table_19;
	reg busy_table_20;
	reg busy_table_21;
	reg busy_table_22;
	reg busy_table_23;
	reg busy_table_24;
	reg busy_table_25;
	reg busy_table_26;
	reg busy_table_27;
	reg busy_table_28;
	reg busy_table_29;
	reg busy_table_30;
	reg busy_table_31;
	reg busy_table_32;
	reg busy_table_33;
	reg busy_table_34;
	reg busy_table_35;
	reg busy_table_36;
	reg busy_table_37;
	reg busy_table_38;
	reg busy_table_39;
	reg busy_table_40;
	reg busy_table_41;
	reg busy_table_42;
	reg busy_table_43;
	reg busy_table_44;
	reg busy_table_45;
	reg busy_table_46;
	reg busy_table_47;
	reg busy_table_48;
	reg busy_table_49;
	reg busy_table_50;
	reg busy_table_51;
	reg busy_table_52;
	reg busy_table_53;
	reg busy_table_54;
	reg busy_table_55;
	reg busy_table_56;
	reg busy_table_57;
	reg busy_table_58;
	reg busy_table_59;
	reg busy_table_60;
	reg busy_table_61;
	reg busy_table_62;
	reg busy_table_63;
	reg is_free_1;
	reg is_free_2;
	reg is_free_3;
	reg is_free_4;
	reg is_free_5;
	reg is_free_6;
	reg is_free_7;
	reg is_free_8;
	reg is_free_9;
	reg is_free_10;
	reg is_free_11;
	reg is_free_12;
	reg is_free_13;
	reg is_free_14;
	reg is_free_15;
	reg is_free_16;
	reg is_free_17;
	reg is_free_18;
	reg is_free_19;
	reg is_free_20;
	reg is_free_21;
	reg is_free_22;
	reg is_free_23;
	reg is_free_24;
	reg is_free_25;
	reg is_free_26;
	reg is_free_27;
	reg is_free_28;
	reg is_free_29;
	reg is_free_30;
	reg is_free_31;
	reg is_free_32;
	reg is_free_33;
	reg is_free_34;
	reg is_free_35;
	reg is_free_36;
	reg is_free_37;
	reg is_free_38;
	reg is_free_39;
	reg is_free_40;
	reg is_free_41;
	reg is_free_42;
	reg is_free_43;
	reg is_free_44;
	reg is_free_45;
	reg is_free_46;
	reg is_free_47;
	reg is_free_48;
	reg is_free_49;
	reg is_free_50;
	reg is_free_51;
	reg is_free_52;
	reg is_free_53;
	reg is_free_54;
	reg is_free_55;
	reg is_free_56;
	reg is_free_57;
	reg is_free_58;
	reg is_free_59;
	reg is_free_60;
	reg is_free_61;
	reg is_free_62;
	reg is_free_63;
	wire [5:0] _free_idx_0_T_61 = (is_free_1 ? 6'h01 : (is_free_2 ? 6'h02 : (is_free_3 ? 6'h03 : (is_free_4 ? 6'h04 : (is_free_5 ? 6'h05 : (is_free_6 ? 6'h06 : (is_free_7 ? 6'h07 : (is_free_8 ? 6'h08 : (is_free_9 ? 6'h09 : (is_free_10 ? 6'h0a : (is_free_11 ? 6'h0b : (is_free_12 ? 6'h0c : (is_free_13 ? 6'h0d : (is_free_14 ? 6'h0e : (is_free_15 ? 6'h0f : (is_free_16 ? 6'h10 : (is_free_17 ? 6'h11 : (is_free_18 ? 6'h12 : (is_free_19 ? 6'h13 : (is_free_20 ? 6'h14 : (is_free_21 ? 6'h15 : (is_free_22 ? 6'h16 : (is_free_23 ? 6'h17 : (is_free_24 ? 6'h18 : (is_free_25 ? 6'h19 : (is_free_26 ? 6'h1a : (is_free_27 ? 6'h1b : (is_free_28 ? 6'h1c : (is_free_29 ? 6'h1d : (is_free_30 ? 6'h1e : (is_free_31 ? 6'h1f : (is_free_32 ? 6'h20 : (is_free_33 ? 6'h21 : (is_free_34 ? 6'h22 : (is_free_35 ? 6'h23 : (is_free_36 ? 6'h24 : (is_free_37 ? 6'h25 : (is_free_38 ? 6'h26 : (is_free_39 ? 6'h27 : (is_free_40 ? 6'h28 : (is_free_41 ? 6'h29 : (is_free_42 ? 6'h2a : (is_free_43 ? 6'h2b : (is_free_44 ? 6'h2c : (is_free_45 ? 6'h2d : (is_free_46 ? 6'h2e : (is_free_47 ? 6'h2f : (is_free_48 ? 6'h30 : (is_free_49 ? 6'h31 : (is_free_50 ? 6'h32 : (is_free_51 ? 6'h33 : (is_free_52 ? 6'h34 : (is_free_53 ? 6'h35 : (is_free_54 ? 6'h36 : (is_free_55 ? 6'h37 : (is_free_56 ? 6'h38 : (is_free_57 ? 6'h39 : (is_free_58 ? 6'h3a : (is_free_59 ? 6'h3b : (is_free_60 ? 6'h3c : (is_free_61 ? 6'h3d : {5'h1f, ~is_free_62})))))))))))))))))))))))))))))))))))))))))))))))))))))))))))));
	wire is_free_mask1_1 = is_free_1 & (_free_idx_0_T_61 != 6'h01);
	wire is_free_mask1_2 = is_free_2 & (_free_idx_0_T_61 != 6'h02);
	wire is_free_mask1_3 = is_free_3 & (_free_idx_0_T_61 != 6'h03);
	wire is_free_mask1_4 = is_free_4 & (_free_idx_0_T_61 != 6'h04);
	wire is_free_mask1_5 = is_free_5 & (_free_idx_0_T_61 != 6'h05);
	wire is_free_mask1_6 = is_free_6 & (_free_idx_0_T_61 != 6'h06);
	wire is_free_mask1_7 = is_free_7 & (_free_idx_0_T_61 != 6'h07);
	wire is_free_mask1_8 = is_free_8 & (_free_idx_0_T_61 != 6'h08);
	wire is_free_mask1_9 = is_free_9 & (_free_idx_0_T_61 != 6'h09);
	wire is_free_mask1_10 = is_free_10 & (_free_idx_0_T_61 != 6'h0a);
	wire is_free_mask1_11 = is_free_11 & (_free_idx_0_T_61 != 6'h0b);
	wire is_free_mask1_12 = is_free_12 & (_free_idx_0_T_61 != 6'h0c);
	wire is_free_mask1_13 = is_free_13 & (_free_idx_0_T_61 != 6'h0d);
	wire is_free_mask1_14 = is_free_14 & (_free_idx_0_T_61 != 6'h0e);
	wire is_free_mask1_15 = is_free_15 & (_free_idx_0_T_61 != 6'h0f);
	wire is_free_mask1_16 = is_free_16 & (_free_idx_0_T_61 != 6'h10);
	wire is_free_mask1_17 = is_free_17 & (_free_idx_0_T_61 != 6'h11);
	wire is_free_mask1_18 = is_free_18 & (_free_idx_0_T_61 != 6'h12);
	wire is_free_mask1_19 = is_free_19 & (_free_idx_0_T_61 != 6'h13);
	wire is_free_mask1_20 = is_free_20 & (_free_idx_0_T_61 != 6'h14);
	wire is_free_mask1_21 = is_free_21 & (_free_idx_0_T_61 != 6'h15);
	wire is_free_mask1_22 = is_free_22 & (_free_idx_0_T_61 != 6'h16);
	wire is_free_mask1_23 = is_free_23 & (_free_idx_0_T_61 != 6'h17);
	wire is_free_mask1_24 = is_free_24 & (_free_idx_0_T_61 != 6'h18);
	wire is_free_mask1_25 = is_free_25 & (_free_idx_0_T_61 != 6'h19);
	wire is_free_mask1_26 = is_free_26 & (_free_idx_0_T_61 != 6'h1a);
	wire is_free_mask1_27 = is_free_27 & (_free_idx_0_T_61 != 6'h1b);
	wire is_free_mask1_28 = is_free_28 & (_free_idx_0_T_61 != 6'h1c);
	wire is_free_mask1_29 = is_free_29 & (_free_idx_0_T_61 != 6'h1d);
	wire is_free_mask1_30 = is_free_30 & (_free_idx_0_T_61 != 6'h1e);
	wire is_free_mask1_31 = is_free_31 & (_free_idx_0_T_61 != 6'h1f);
	wire is_free_mask1_32 = is_free_32 & (_free_idx_0_T_61 != 6'h20);
	wire is_free_mask1_33 = is_free_33 & (_free_idx_0_T_61 != 6'h21);
	wire is_free_mask1_34 = is_free_34 & (_free_idx_0_T_61 != 6'h22);
	wire is_free_mask1_35 = is_free_35 & (_free_idx_0_T_61 != 6'h23);
	wire is_free_mask1_36 = is_free_36 & (_free_idx_0_T_61 != 6'h24);
	wire is_free_mask1_37 = is_free_37 & (_free_idx_0_T_61 != 6'h25);
	wire is_free_mask1_38 = is_free_38 & (_free_idx_0_T_61 != 6'h26);
	wire is_free_mask1_39 = is_free_39 & (_free_idx_0_T_61 != 6'h27);
	wire is_free_mask1_40 = is_free_40 & (_free_idx_0_T_61 != 6'h28);
	wire is_free_mask1_41 = is_free_41 & (_free_idx_0_T_61 != 6'h29);
	wire is_free_mask1_42 = is_free_42 & (_free_idx_0_T_61 != 6'h2a);
	wire is_free_mask1_43 = is_free_43 & (_free_idx_0_T_61 != 6'h2b);
	wire is_free_mask1_44 = is_free_44 & (_free_idx_0_T_61 != 6'h2c);
	wire is_free_mask1_45 = is_free_45 & (_free_idx_0_T_61 != 6'h2d);
	wire is_free_mask1_46 = is_free_46 & (_free_idx_0_T_61 != 6'h2e);
	wire is_free_mask1_47 = is_free_47 & (_free_idx_0_T_61 != 6'h2f);
	wire is_free_mask1_48 = is_free_48 & (_free_idx_0_T_61 != 6'h30);
	wire is_free_mask1_49 = is_free_49 & (_free_idx_0_T_61 != 6'h31);
	wire is_free_mask1_50 = is_free_50 & (_free_idx_0_T_61 != 6'h32);
	wire is_free_mask1_51 = is_free_51 & (_free_idx_0_T_61 != 6'h33);
	wire is_free_mask1_52 = is_free_52 & (_free_idx_0_T_61 != 6'h34);
	wire is_free_mask1_53 = is_free_53 & (_free_idx_0_T_61 != 6'h35);
	wire is_free_mask1_54 = is_free_54 & (_free_idx_0_T_61 != 6'h36);
	wire is_free_mask1_55 = is_free_55 & (_free_idx_0_T_61 != 6'h37);
	wire is_free_mask1_56 = is_free_56 & (_free_idx_0_T_61 != 6'h38);
	wire is_free_mask1_57 = is_free_57 & (_free_idx_0_T_61 != 6'h39);
	wire is_free_mask1_58 = is_free_58 & (_free_idx_0_T_61 != 6'h3a);
	wire is_free_mask1_59 = is_free_59 & (_free_idx_0_T_61 != 6'h3b);
	wire is_free_mask1_60 = is_free_60 & (_free_idx_0_T_61 != 6'h3c);
	wire is_free_mask1_61 = is_free_61 & (_free_idx_0_T_61 != 6'h3d);
	wire is_free_mask1_62 = is_free_62 & (_free_idx_0_T_61 != 6'h3e);
	wire need_alloc_0 = (io_enq_bits_0_valid & io_enq_bits_0_rf_wen) & |io_enq_bits_0_l_rd;
	wire need_alloc_1 = (io_enq_bits_1_valid & io_enq_bits_1_rf_wen) & |io_enq_bits_1_l_rd;
	wire [5:0] prd_0 = (need_alloc_0 ? _free_idx_0_T_61 : 6'h00);
	wire [5:0] prd_1 = (need_alloc_1 ? (need_alloc_0 ? (is_free_mask1_1 ? 6'h01 : (is_free_mask1_2 ? 6'h02 : (is_free_mask1_3 ? 6'h03 : (is_free_mask1_4 ? 6'h04 : (is_free_mask1_5 ? 6'h05 : (is_free_mask1_6 ? 6'h06 : (is_free_mask1_7 ? 6'h07 : (is_free_mask1_8 ? 6'h08 : (is_free_mask1_9 ? 6'h09 : (is_free_mask1_10 ? 6'h0a : (is_free_mask1_11 ? 6'h0b : (is_free_mask1_12 ? 6'h0c : (is_free_mask1_13 ? 6'h0d : (is_free_mask1_14 ? 6'h0e : (is_free_mask1_15 ? 6'h0f : (is_free_mask1_16 ? 6'h10 : (is_free_mask1_17 ? 6'h11 : (is_free_mask1_18 ? 6'h12 : (is_free_mask1_19 ? 6'h13 : (is_free_mask1_20 ? 6'h14 : (is_free_mask1_21 ? 6'h15 : (is_free_mask1_22 ? 6'h16 : (is_free_mask1_23 ? 6'h17 : (is_free_mask1_24 ? 6'h18 : (is_free_mask1_25 ? 6'h19 : (is_free_mask1_26 ? 6'h1a : (is_free_mask1_27 ? 6'h1b : (is_free_mask1_28 ? 6'h1c : (is_free_mask1_29 ? 6'h1d : (is_free_mask1_30 ? 6'h1e : (is_free_mask1_31 ? 6'h1f : (is_free_mask1_32 ? 6'h20 : (is_free_mask1_33 ? 6'h21 : (is_free_mask1_34 ? 6'h22 : (is_free_mask1_35 ? 6'h23 : (is_free_mask1_36 ? 6'h24 : (is_free_mask1_37 ? 6'h25 : (is_free_mask1_38 ? 6'h26 : (is_free_mask1_39 ? 6'h27 : (is_free_mask1_40 ? 6'h28 : (is_free_mask1_41 ? 6'h29 : (is_free_mask1_42 ? 6'h2a : (is_free_mask1_43 ? 6'h2b : (is_free_mask1_44 ? 6'h2c : (is_free_mask1_45 ? 6'h2d : (is_free_mask1_46 ? 6'h2e : (is_free_mask1_47 ? 6'h2f : (is_free_mask1_48 ? 6'h30 : (is_free_mask1_49 ? 6'h31 : (is_free_mask1_50 ? 6'h32 : (is_free_mask1_51 ? 6'h33 : (is_free_mask1_52 ? 6'h34 : (is_free_mask1_53 ? 6'h35 : (is_free_mask1_54 ? 6'h36 : (is_free_mask1_55 ? 6'h37 : (is_free_mask1_56 ? 6'h38 : (is_free_mask1_57 ? 6'h39 : (is_free_mask1_58 ? 6'h3a : (is_free_mask1_59 ? 6'h3b : (is_free_mask1_60 ? 6'h3c : (is_free_mask1_61 ? 6'h3d : {5'h1f, ~is_free_mask1_62}))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) : _free_idx_0_T_61) : 6'h00);
	wire need_2 = need_alloc_0 & need_alloc_1;
	wire can_alloc = (need_2 ? |{is_free_63 & (_free_idx_0_T_61 != 6'h3f), is_free_mask1_62, is_free_mask1_61, is_free_mask1_60, is_free_mask1_59, is_free_mask1_58, is_free_mask1_57, is_free_mask1_56, is_free_mask1_55, is_free_mask1_54, is_free_mask1_53, is_free_mask1_52, is_free_mask1_51, is_free_mask1_50, is_free_mask1_49, is_free_mask1_48, is_free_mask1_47, is_free_mask1_46, is_free_mask1_45, is_free_mask1_44, is_free_mask1_43, is_free_mask1_42, is_free_mask1_41, is_free_mask1_40, is_free_mask1_39, is_free_mask1_38, is_free_mask1_37, is_free_mask1_36, is_free_mask1_35, is_free_mask1_34, is_free_mask1_33, is_free_mask1_32, is_free_mask1_31, is_free_mask1_30, is_free_mask1_29, is_free_mask1_28, is_free_mask1_27, is_free_mask1_26, is_free_mask1_25, is_free_mask1_24, is_free_mask1_23, is_free_mask1_22, is_free_mask1_21, is_free_mask1_20, is_free_mask1_19, is_free_mask1_18, is_free_mask1_17, is_free_mask1_16, is_free_mask1_15, is_free_mask1_14, is_free_mask1_13, is_free_mask1_12, is_free_mask1_11, is_free_mask1_10, is_free_mask1_9, is_free_mask1_8, is_free_mask1_7, is_free_mask1_6, is_free_mask1_5, is_free_mask1_4, is_free_mask1_3, is_free_mask1_2, is_free_mask1_1} : (need_alloc_0 ^ ~need_alloc_1) | (|{is_free_63, is_free_62, is_free_61, is_free_60, is_free_59, is_free_58, is_free_57, is_free_56, is_free_55, is_free_54, is_free_53, is_free_52, is_free_51, is_free_50, is_free_49, is_free_48, is_free_47, is_free_46, is_free_45, is_free_44, is_free_43, is_free_42, is_free_41, is_free_40, is_free_39, is_free_38, is_free_37, is_free_36, is_free_35, is_free_34, is_free_33, is_free_32, is_free_31, is_free_30, is_free_29, is_free_28, is_free_27, is_free_26, is_free_25, is_free_24, is_free_23, is_free_22, is_free_21, is_free_20, is_free_19, is_free_18, is_free_17, is_free_16, is_free_15, is_free_14, is_free_13, is_free_12, is_free_11, is_free_10, is_free_9, is_free_8, is_free_7, is_free_6, is_free_5, is_free_4, is_free_3, is_free_2, is_free_1}));
	wire dep1_rs1_on_0 = (need_alloc_0 & (io_enq_bits_1_l_rs1 == io_enq_bits_0_l_rd)) & |io_enq_bits_1_l_rs1;
	wire dep1_rs2_on_0 = (need_alloc_0 & (io_enq_bits_1_l_rs2 == io_enq_bits_0_l_rd)) & |io_enq_bits_1_l_rs2;
	wire [191:0] _GEN = {rat_31, rat_30, rat_29, rat_28, rat_27, rat_26, rat_25, rat_24, rat_23, rat_22, rat_21, rat_20, rat_19, rat_18, rat_17, rat_16, rat_15, rat_14, rat_13, rat_12, rat_11, rat_10, rat_9, rat_8, rat_7, rat_6, rat_5, rat_4, rat_3, rat_2, rat_1, rat_0};
	wire [63:0] _GEN_0 = {busy_table_63, busy_table_62, busy_table_61, busy_table_60, busy_table_59, busy_table_58, busy_table_57, busy_table_56, busy_table_55, busy_table_54, busy_table_53, busy_table_52, busy_table_51, busy_table_50, busy_table_49, busy_table_48, busy_table_47, busy_table_46, busy_table_45, busy_table_44, busy_table_43, busy_table_42, busy_table_41, busy_table_40, busy_table_39, busy_table_38, busy_table_37, busy_table_36, busy_table_35, busy_table_34, busy_table_33, busy_table_32, busy_table_31, busy_table_30, busy_table_29, busy_table_28, busy_table_27, busy_table_26, busy_table_25, busy_table_24, busy_table_23, busy_table_22, busy_table_21, busy_table_20, busy_table_19, busy_table_18, busy_table_17, busy_table_16, busy_table_15, busy_table_14, busy_table_13, busy_table_12, busy_table_11, busy_table_10, busy_table_9, busy_table_8, busy_table_7, busy_table_6, busy_table_5, busy_table_4, busy_table_3, busy_table_2, busy_table_1, 1'h0};
	always @(posedge clock)
		if (reset) begin
			rat_0 <= 6'h00;
			rat_1 <= 6'h00;
			rat_2 <= 6'h00;
			rat_3 <= 6'h00;
			rat_4 <= 6'h00;
			rat_5 <= 6'h00;
			rat_6 <= 6'h00;
			rat_7 <= 6'h00;
			rat_8 <= 6'h00;
			rat_9 <= 6'h00;
			rat_10 <= 6'h00;
			rat_11 <= 6'h00;
			rat_12 <= 6'h00;
			rat_13 <= 6'h00;
			rat_14 <= 6'h00;
			rat_15 <= 6'h00;
			rat_16 <= 6'h00;
			rat_17 <= 6'h00;
			rat_18 <= 6'h00;
			rat_19 <= 6'h00;
			rat_20 <= 6'h00;
			rat_21 <= 6'h00;
			rat_22 <= 6'h00;
			rat_23 <= 6'h00;
			rat_24 <= 6'h00;
			rat_25 <= 6'h00;
			rat_26 <= 6'h00;
			rat_27 <= 6'h00;
			rat_28 <= 6'h00;
			rat_29 <= 6'h00;
			rat_30 <= 6'h00;
			rat_31 <= 6'h00;
			busy_table_1 <= 1'h0;
			busy_table_2 <= 1'h0;
			busy_table_3 <= 1'h0;
			busy_table_4 <= 1'h0;
			busy_table_5 <= 1'h0;
			busy_table_6 <= 1'h0;
			busy_table_7 <= 1'h0;
			busy_table_8 <= 1'h0;
			busy_table_9 <= 1'h0;
			busy_table_10 <= 1'h0;
			busy_table_11 <= 1'h0;
			busy_table_12 <= 1'h0;
			busy_table_13 <= 1'h0;
			busy_table_14 <= 1'h0;
			busy_table_15 <= 1'h0;
			busy_table_16 <= 1'h0;
			busy_table_17 <= 1'h0;
			busy_table_18 <= 1'h0;
			busy_table_19 <= 1'h0;
			busy_table_20 <= 1'h0;
			busy_table_21 <= 1'h0;
			busy_table_22 <= 1'h0;
			busy_table_23 <= 1'h0;
			busy_table_24 <= 1'h0;
			busy_table_25 <= 1'h0;
			busy_table_26 <= 1'h0;
			busy_table_27 <= 1'h0;
			busy_table_28 <= 1'h0;
			busy_table_29 <= 1'h0;
			busy_table_30 <= 1'h0;
			busy_table_31 <= 1'h0;
			busy_table_32 <= 1'h0;
			busy_table_33 <= 1'h0;
			busy_table_34 <= 1'h0;
			busy_table_35 <= 1'h0;
			busy_table_36 <= 1'h0;
			busy_table_37 <= 1'h0;
			busy_table_38 <= 1'h0;
			busy_table_39 <= 1'h0;
			busy_table_40 <= 1'h0;
			busy_table_41 <= 1'h0;
			busy_table_42 <= 1'h0;
			busy_table_43 <= 1'h0;
			busy_table_44 <= 1'h0;
			busy_table_45 <= 1'h0;
			busy_table_46 <= 1'h0;
			busy_table_47 <= 1'h0;
			busy_table_48 <= 1'h0;
			busy_table_49 <= 1'h0;
			busy_table_50 <= 1'h0;
			busy_table_51 <= 1'h0;
			busy_table_52 <= 1'h0;
			busy_table_53 <= 1'h0;
			busy_table_54 <= 1'h0;
			busy_table_55 <= 1'h0;
			busy_table_56 <= 1'h0;
			busy_table_57 <= 1'h0;
			busy_table_58 <= 1'h0;
			busy_table_59 <= 1'h0;
			busy_table_60 <= 1'h0;
			busy_table_61 <= 1'h0;
			busy_table_62 <= 1'h0;
			busy_table_63 <= 1'h0;
			is_free_1 <= 1'h1;
			is_free_2 <= 1'h1;
			is_free_3 <= 1'h1;
			is_free_4 <= 1'h1;
			is_free_5 <= 1'h1;
			is_free_6 <= 1'h1;
			is_free_7 <= 1'h1;
			is_free_8 <= 1'h1;
			is_free_9 <= 1'h1;
			is_free_10 <= 1'h1;
			is_free_11 <= 1'h1;
			is_free_12 <= 1'h1;
			is_free_13 <= 1'h1;
			is_free_14 <= 1'h1;
			is_free_15 <= 1'h1;
			is_free_16 <= 1'h1;
			is_free_17 <= 1'h1;
			is_free_18 <= 1'h1;
			is_free_19 <= 1'h1;
			is_free_20 <= 1'h1;
			is_free_21 <= 1'h1;
			is_free_22 <= 1'h1;
			is_free_23 <= 1'h1;
			is_free_24 <= 1'h1;
			is_free_25 <= 1'h1;
			is_free_26 <= 1'h1;
			is_free_27 <= 1'h1;
			is_free_28 <= 1'h1;
			is_free_29 <= 1'h1;
			is_free_30 <= 1'h1;
			is_free_31 <= 1'h1;
			is_free_32 <= 1'h1;
			is_free_33 <= 1'h1;
			is_free_34 <= 1'h1;
			is_free_35 <= 1'h1;
			is_free_36 <= 1'h1;
			is_free_37 <= 1'h1;
			is_free_38 <= 1'h1;
			is_free_39 <= 1'h1;
			is_free_40 <= 1'h1;
			is_free_41 <= 1'h1;
			is_free_42 <= 1'h1;
			is_free_43 <= 1'h1;
			is_free_44 <= 1'h1;
			is_free_45 <= 1'h1;
			is_free_46 <= 1'h1;
			is_free_47 <= 1'h1;
			is_free_48 <= 1'h1;
			is_free_49 <= 1'h1;
			is_free_50 <= 1'h1;
			is_free_51 <= 1'h1;
			is_free_52 <= 1'h1;
			is_free_53 <= 1'h1;
			is_free_54 <= 1'h1;
			is_free_55 <= 1'h1;
			is_free_56 <= 1'h1;
			is_free_57 <= 1'h1;
			is_free_58 <= 1'h1;
			is_free_59 <= 1'h1;
			is_free_60 <= 1'h1;
			is_free_61 <= 1'h1;
			is_free_62 <= 1'h1;
			is_free_63 <= 1'h1;
		end
		else begin : sv2v_autoblock_1
			reg fire;
			reg _alloc_by_0_T_124;
			reg _alloc_by_1_T_124;
			reg is_alloc;
			reg is_rbk_free;
			reg is_alloc_1;
			reg is_rbk_free_1;
			reg is_alloc_2;
			reg is_rbk_free_2;
			reg is_alloc_3;
			reg is_rbk_free_3;
			reg is_alloc_4;
			reg is_rbk_free_4;
			reg is_alloc_5;
			reg is_rbk_free_5;
			reg is_alloc_6;
			reg is_rbk_free_6;
			reg is_alloc_7;
			reg is_rbk_free_7;
			reg is_alloc_8;
			reg is_rbk_free_8;
			reg is_alloc_9;
			reg is_rbk_free_9;
			reg is_alloc_10;
			reg is_rbk_free_10;
			reg is_alloc_11;
			reg is_rbk_free_11;
			reg is_alloc_12;
			reg is_rbk_free_12;
			reg is_alloc_13;
			reg is_rbk_free_13;
			reg is_alloc_14;
			reg is_rbk_free_14;
			reg is_alloc_15;
			reg is_rbk_free_15;
			reg is_alloc_16;
			reg is_rbk_free_16;
			reg is_alloc_17;
			reg is_rbk_free_17;
			reg is_alloc_18;
			reg is_rbk_free_18;
			reg is_alloc_19;
			reg is_rbk_free_19;
			reg is_alloc_20;
			reg is_rbk_free_20;
			reg is_alloc_21;
			reg is_rbk_free_21;
			reg is_alloc_22;
			reg is_rbk_free_22;
			reg is_alloc_23;
			reg is_rbk_free_23;
			reg is_alloc_24;
			reg is_rbk_free_24;
			reg is_alloc_25;
			reg is_rbk_free_25;
			reg is_alloc_26;
			reg is_rbk_free_26;
			reg is_alloc_27;
			reg is_rbk_free_27;
			reg is_alloc_28;
			reg is_rbk_free_28;
			reg is_alloc_29;
			reg is_rbk_free_29;
			reg is_alloc_30;
			reg is_rbk_free_30;
			reg is_alloc_31;
			reg is_rbk_free_31;
			reg is_alloc_32;
			reg is_rbk_free_32;
			reg is_alloc_33;
			reg is_rbk_free_33;
			reg is_alloc_34;
			reg is_rbk_free_34;
			reg is_alloc_35;
			reg is_rbk_free_35;
			reg is_alloc_36;
			reg is_rbk_free_36;
			reg is_alloc_37;
			reg is_rbk_free_37;
			reg is_alloc_38;
			reg is_rbk_free_38;
			reg is_alloc_39;
			reg is_rbk_free_39;
			reg is_alloc_40;
			reg is_rbk_free_40;
			reg is_alloc_41;
			reg is_rbk_free_41;
			reg is_alloc_42;
			reg is_rbk_free_42;
			reg is_alloc_43;
			reg is_rbk_free_43;
			reg is_alloc_44;
			reg is_rbk_free_44;
			reg is_alloc_45;
			reg is_rbk_free_45;
			reg is_alloc_46;
			reg is_rbk_free_46;
			reg is_alloc_47;
			reg is_rbk_free_47;
			reg is_alloc_48;
			reg is_rbk_free_48;
			reg is_alloc_49;
			reg is_rbk_free_49;
			reg is_alloc_50;
			reg is_rbk_free_50;
			reg is_alloc_51;
			reg is_rbk_free_51;
			reg is_alloc_52;
			reg is_rbk_free_52;
			reg is_alloc_53;
			reg is_rbk_free_53;
			reg is_alloc_54;
			reg is_rbk_free_54;
			reg is_alloc_55;
			reg is_rbk_free_55;
			reg is_alloc_56;
			reg is_rbk_free_56;
			reg is_alloc_57;
			reg is_rbk_free_57;
			reg is_alloc_58;
			reg is_rbk_free_58;
			reg is_alloc_59;
			reg is_rbk_free_59;
			reg is_alloc_60;
			reg is_rbk_free_60;
			reg is_alloc_61;
			reg is_rbk_free_61;
			reg is_alloc_62;
			reg is_rbk_free_62;
			is_rbk_free = io_rbk_valid & (io_rbk_p_rd == 6'h01);
			is_rbk_free_1 = io_rbk_valid & (io_rbk_p_rd == 6'h02);
			is_rbk_free_2 = io_rbk_valid & (io_rbk_p_rd == 6'h03);
			is_rbk_free_3 = io_rbk_valid & (io_rbk_p_rd == 6'h04);
			is_rbk_free_4 = io_rbk_valid & (io_rbk_p_rd == 6'h05);
			is_rbk_free_5 = io_rbk_valid & (io_rbk_p_rd == 6'h06);
			is_rbk_free_6 = io_rbk_valid & (io_rbk_p_rd == 6'h07);
			is_rbk_free_7 = io_rbk_valid & (io_rbk_p_rd == 6'h08);
			is_rbk_free_8 = io_rbk_valid & (io_rbk_p_rd == 6'h09);
			is_rbk_free_9 = io_rbk_valid & (io_rbk_p_rd == 6'h0a);
			is_rbk_free_10 = io_rbk_valid & (io_rbk_p_rd == 6'h0b);
			is_rbk_free_11 = io_rbk_valid & (io_rbk_p_rd == 6'h0c);
			is_rbk_free_12 = io_rbk_valid & (io_rbk_p_rd == 6'h0d);
			is_rbk_free_13 = io_rbk_valid & (io_rbk_p_rd == 6'h0e);
			is_rbk_free_14 = io_rbk_valid & (io_rbk_p_rd == 6'h0f);
			is_rbk_free_15 = io_rbk_valid & (io_rbk_p_rd == 6'h10);
			is_rbk_free_16 = io_rbk_valid & (io_rbk_p_rd == 6'h11);
			is_rbk_free_17 = io_rbk_valid & (io_rbk_p_rd == 6'h12);
			is_rbk_free_18 = io_rbk_valid & (io_rbk_p_rd == 6'h13);
			is_rbk_free_19 = io_rbk_valid & (io_rbk_p_rd == 6'h14);
			is_rbk_free_20 = io_rbk_valid & (io_rbk_p_rd == 6'h15);
			is_rbk_free_21 = io_rbk_valid & (io_rbk_p_rd == 6'h16);
			is_rbk_free_22 = io_rbk_valid & (io_rbk_p_rd == 6'h17);
			is_rbk_free_23 = io_rbk_valid & (io_rbk_p_rd == 6'h18);
			is_rbk_free_24 = io_rbk_valid & (io_rbk_p_rd == 6'h19);
			is_rbk_free_25 = io_rbk_valid & (io_rbk_p_rd == 6'h1a);
			is_rbk_free_26 = io_rbk_valid & (io_rbk_p_rd == 6'h1b);
			is_rbk_free_27 = io_rbk_valid & (io_rbk_p_rd == 6'h1c);
			is_rbk_free_28 = io_rbk_valid & (io_rbk_p_rd == 6'h1d);
			is_rbk_free_29 = io_rbk_valid & (io_rbk_p_rd == 6'h1e);
			is_rbk_free_30 = io_rbk_valid & (io_rbk_p_rd == 6'h1f);
			is_rbk_free_31 = io_rbk_valid & (io_rbk_p_rd == 6'h20);
			is_rbk_free_32 = io_rbk_valid & (io_rbk_p_rd == 6'h21);
			is_rbk_free_33 = io_rbk_valid & (io_rbk_p_rd == 6'h22);
			is_rbk_free_34 = io_rbk_valid & (io_rbk_p_rd == 6'h23);
			is_rbk_free_35 = io_rbk_valid & (io_rbk_p_rd == 6'h24);
			is_rbk_free_36 = io_rbk_valid & (io_rbk_p_rd == 6'h25);
			is_rbk_free_37 = io_rbk_valid & (io_rbk_p_rd == 6'h26);
			is_rbk_free_38 = io_rbk_valid & (io_rbk_p_rd == 6'h27);
			is_rbk_free_39 = io_rbk_valid & (io_rbk_p_rd == 6'h28);
			is_rbk_free_40 = io_rbk_valid & (io_rbk_p_rd == 6'h29);
			is_rbk_free_41 = io_rbk_valid & (io_rbk_p_rd == 6'h2a);
			is_rbk_free_42 = io_rbk_valid & (io_rbk_p_rd == 6'h2b);
			is_rbk_free_43 = io_rbk_valid & (io_rbk_p_rd == 6'h2c);
			is_rbk_free_44 = io_rbk_valid & (io_rbk_p_rd == 6'h2d);
			is_rbk_free_45 = io_rbk_valid & (io_rbk_p_rd == 6'h2e);
			is_rbk_free_46 = io_rbk_valid & (io_rbk_p_rd == 6'h2f);
			is_rbk_free_47 = io_rbk_valid & (io_rbk_p_rd == 6'h30);
			is_rbk_free_48 = io_rbk_valid & (io_rbk_p_rd == 6'h31);
			is_rbk_free_49 = io_rbk_valid & (io_rbk_p_rd == 6'h32);
			is_rbk_free_50 = io_rbk_valid & (io_rbk_p_rd == 6'h33);
			is_rbk_free_51 = io_rbk_valid & (io_rbk_p_rd == 6'h34);
			is_rbk_free_52 = io_rbk_valid & (io_rbk_p_rd == 6'h35);
			is_rbk_free_53 = io_rbk_valid & (io_rbk_p_rd == 6'h36);
			is_rbk_free_54 = io_rbk_valid & (io_rbk_p_rd == 6'h37);
			is_rbk_free_55 = io_rbk_valid & (io_rbk_p_rd == 6'h38);
			is_rbk_free_56 = io_rbk_valid & (io_rbk_p_rd == 6'h39);
			is_rbk_free_57 = io_rbk_valid & (io_rbk_p_rd == 6'h3a);
			is_rbk_free_58 = io_rbk_valid & (io_rbk_p_rd == 6'h3b);
			is_rbk_free_59 = io_rbk_valid & (io_rbk_p_rd == 6'h3c);
			is_rbk_free_60 = io_rbk_valid & (io_rbk_p_rd == 6'h3d);
			is_rbk_free_61 = io_rbk_valid & (io_rbk_p_rd == 6'h3e);
			is_rbk_free_62 = io_rbk_valid & (&io_rbk_p_rd);
			fire = ((io_enq_valid & io_deq_ready) & can_alloc) & ~io_rbk_active;
			_alloc_by_0_T_124 = fire & need_alloc_0;
			_alloc_by_1_T_124 = fire & need_alloc_1;
			is_alloc = (_alloc_by_0_T_124 & (prd_0 == 6'h01)) | (_alloc_by_1_T_124 & (prd_1 == 6'h01));
			is_alloc_1 = (_alloc_by_0_T_124 & (prd_0 == 6'h02)) | (_alloc_by_1_T_124 & (prd_1 == 6'h02));
			is_alloc_2 = (_alloc_by_0_T_124 & (prd_0 == 6'h03)) | (_alloc_by_1_T_124 & (prd_1 == 6'h03));
			is_alloc_3 = (_alloc_by_0_T_124 & (prd_0 == 6'h04)) | (_alloc_by_1_T_124 & (prd_1 == 6'h04));
			is_alloc_4 = (_alloc_by_0_T_124 & (prd_0 == 6'h05)) | (_alloc_by_1_T_124 & (prd_1 == 6'h05));
			is_alloc_5 = (_alloc_by_0_T_124 & (prd_0 == 6'h06)) | (_alloc_by_1_T_124 & (prd_1 == 6'h06));
			is_alloc_6 = (_alloc_by_0_T_124 & (prd_0 == 6'h07)) | (_alloc_by_1_T_124 & (prd_1 == 6'h07));
			is_alloc_7 = (_alloc_by_0_T_124 & (prd_0 == 6'h08)) | (_alloc_by_1_T_124 & (prd_1 == 6'h08));
			is_alloc_8 = (_alloc_by_0_T_124 & (prd_0 == 6'h09)) | (_alloc_by_1_T_124 & (prd_1 == 6'h09));
			is_alloc_9 = (_alloc_by_0_T_124 & (prd_0 == 6'h0a)) | (_alloc_by_1_T_124 & (prd_1 == 6'h0a));
			is_alloc_10 = (_alloc_by_0_T_124 & (prd_0 == 6'h0b)) | (_alloc_by_1_T_124 & (prd_1 == 6'h0b));
			is_alloc_11 = (_alloc_by_0_T_124 & (prd_0 == 6'h0c)) | (_alloc_by_1_T_124 & (prd_1 == 6'h0c));
			is_alloc_12 = (_alloc_by_0_T_124 & (prd_0 == 6'h0d)) | (_alloc_by_1_T_124 & (prd_1 == 6'h0d));
			is_alloc_13 = (_alloc_by_0_T_124 & (prd_0 == 6'h0e)) | (_alloc_by_1_T_124 & (prd_1 == 6'h0e));
			is_alloc_14 = (_alloc_by_0_T_124 & (prd_0 == 6'h0f)) | (_alloc_by_1_T_124 & (prd_1 == 6'h0f));
			is_alloc_15 = (_alloc_by_0_T_124 & (prd_0 == 6'h10)) | (_alloc_by_1_T_124 & (prd_1 == 6'h10));
			is_alloc_16 = (_alloc_by_0_T_124 & (prd_0 == 6'h11)) | (_alloc_by_1_T_124 & (prd_1 == 6'h11));
			is_alloc_17 = (_alloc_by_0_T_124 & (prd_0 == 6'h12)) | (_alloc_by_1_T_124 & (prd_1 == 6'h12));
			is_alloc_18 = (_alloc_by_0_T_124 & (prd_0 == 6'h13)) | (_alloc_by_1_T_124 & (prd_1 == 6'h13));
			is_alloc_19 = (_alloc_by_0_T_124 & (prd_0 == 6'h14)) | (_alloc_by_1_T_124 & (prd_1 == 6'h14));
			is_alloc_20 = (_alloc_by_0_T_124 & (prd_0 == 6'h15)) | (_alloc_by_1_T_124 & (prd_1 == 6'h15));
			is_alloc_21 = (_alloc_by_0_T_124 & (prd_0 == 6'h16)) | (_alloc_by_1_T_124 & (prd_1 == 6'h16));
			is_alloc_22 = (_alloc_by_0_T_124 & (prd_0 == 6'h17)) | (_alloc_by_1_T_124 & (prd_1 == 6'h17));
			is_alloc_23 = (_alloc_by_0_T_124 & (prd_0 == 6'h18)) | (_alloc_by_1_T_124 & (prd_1 == 6'h18));
			is_alloc_24 = (_alloc_by_0_T_124 & (prd_0 == 6'h19)) | (_alloc_by_1_T_124 & (prd_1 == 6'h19));
			is_alloc_25 = (_alloc_by_0_T_124 & (prd_0 == 6'h1a)) | (_alloc_by_1_T_124 & (prd_1 == 6'h1a));
			is_alloc_26 = (_alloc_by_0_T_124 & (prd_0 == 6'h1b)) | (_alloc_by_1_T_124 & (prd_1 == 6'h1b));
			is_alloc_27 = (_alloc_by_0_T_124 & (prd_0 == 6'h1c)) | (_alloc_by_1_T_124 & (prd_1 == 6'h1c));
			is_alloc_28 = (_alloc_by_0_T_124 & (prd_0 == 6'h1d)) | (_alloc_by_1_T_124 & (prd_1 == 6'h1d));
			is_alloc_29 = (_alloc_by_0_T_124 & (prd_0 == 6'h1e)) | (_alloc_by_1_T_124 & (prd_1 == 6'h1e));
			is_alloc_30 = (_alloc_by_0_T_124 & (prd_0 == 6'h1f)) | (_alloc_by_1_T_124 & (prd_1 == 6'h1f));
			is_alloc_31 = (_alloc_by_0_T_124 & (prd_0 == 6'h20)) | (_alloc_by_1_T_124 & (prd_1 == 6'h20));
			is_alloc_32 = (_alloc_by_0_T_124 & (prd_0 == 6'h21)) | (_alloc_by_1_T_124 & (prd_1 == 6'h21));
			is_alloc_33 = (_alloc_by_0_T_124 & (prd_0 == 6'h22)) | (_alloc_by_1_T_124 & (prd_1 == 6'h22));
			is_alloc_34 = (_alloc_by_0_T_124 & (prd_0 == 6'h23)) | (_alloc_by_1_T_124 & (prd_1 == 6'h23));
			is_alloc_35 = (_alloc_by_0_T_124 & (prd_0 == 6'h24)) | (_alloc_by_1_T_124 & (prd_1 == 6'h24));
			is_alloc_36 = (_alloc_by_0_T_124 & (prd_0 == 6'h25)) | (_alloc_by_1_T_124 & (prd_1 == 6'h25));
			is_alloc_37 = (_alloc_by_0_T_124 & (prd_0 == 6'h26)) | (_alloc_by_1_T_124 & (prd_1 == 6'h26));
			is_alloc_38 = (_alloc_by_0_T_124 & (prd_0 == 6'h27)) | (_alloc_by_1_T_124 & (prd_1 == 6'h27));
			is_alloc_39 = (_alloc_by_0_T_124 & (prd_0 == 6'h28)) | (_alloc_by_1_T_124 & (prd_1 == 6'h28));
			is_alloc_40 = (_alloc_by_0_T_124 & (prd_0 == 6'h29)) | (_alloc_by_1_T_124 & (prd_1 == 6'h29));
			is_alloc_41 = (_alloc_by_0_T_124 & (prd_0 == 6'h2a)) | (_alloc_by_1_T_124 & (prd_1 == 6'h2a));
			is_alloc_42 = (_alloc_by_0_T_124 & (prd_0 == 6'h2b)) | (_alloc_by_1_T_124 & (prd_1 == 6'h2b));
			is_alloc_43 = (_alloc_by_0_T_124 & (prd_0 == 6'h2c)) | (_alloc_by_1_T_124 & (prd_1 == 6'h2c));
			is_alloc_44 = (_alloc_by_0_T_124 & (prd_0 == 6'h2d)) | (_alloc_by_1_T_124 & (prd_1 == 6'h2d));
			is_alloc_45 = (_alloc_by_0_T_124 & (prd_0 == 6'h2e)) | (_alloc_by_1_T_124 & (prd_1 == 6'h2e));
			is_alloc_46 = (_alloc_by_0_T_124 & (prd_0 == 6'h2f)) | (_alloc_by_1_T_124 & (prd_1 == 6'h2f));
			is_alloc_47 = (_alloc_by_0_T_124 & (prd_0 == 6'h30)) | (_alloc_by_1_T_124 & (prd_1 == 6'h30));
			is_alloc_48 = (_alloc_by_0_T_124 & (prd_0 == 6'h31)) | (_alloc_by_1_T_124 & (prd_1 == 6'h31));
			is_alloc_49 = (_alloc_by_0_T_124 & (prd_0 == 6'h32)) | (_alloc_by_1_T_124 & (prd_1 == 6'h32));
			is_alloc_50 = (_alloc_by_0_T_124 & (prd_0 == 6'h33)) | (_alloc_by_1_T_124 & (prd_1 == 6'h33));
			is_alloc_51 = (_alloc_by_0_T_124 & (prd_0 == 6'h34)) | (_alloc_by_1_T_124 & (prd_1 == 6'h34));
			is_alloc_52 = (_alloc_by_0_T_124 & (prd_0 == 6'h35)) | (_alloc_by_1_T_124 & (prd_1 == 6'h35));
			is_alloc_53 = (_alloc_by_0_T_124 & (prd_0 == 6'h36)) | (_alloc_by_1_T_124 & (prd_1 == 6'h36));
			is_alloc_54 = (_alloc_by_0_T_124 & (prd_0 == 6'h37)) | (_alloc_by_1_T_124 & (prd_1 == 6'h37));
			is_alloc_55 = (_alloc_by_0_T_124 & (prd_0 == 6'h38)) | (_alloc_by_1_T_124 & (prd_1 == 6'h38));
			is_alloc_56 = (_alloc_by_0_T_124 & (prd_0 == 6'h39)) | (_alloc_by_1_T_124 & (prd_1 == 6'h39));
			is_alloc_57 = (_alloc_by_0_T_124 & (prd_0 == 6'h3a)) | (_alloc_by_1_T_124 & (prd_1 == 6'h3a));
			is_alloc_58 = (_alloc_by_0_T_124 & (prd_0 == 6'h3b)) | (_alloc_by_1_T_124 & (prd_1 == 6'h3b));
			is_alloc_59 = (_alloc_by_0_T_124 & (prd_0 == 6'h3c)) | (_alloc_by_1_T_124 & (prd_1 == 6'h3c));
			is_alloc_60 = (_alloc_by_0_T_124 & (prd_0 == 6'h3d)) | (_alloc_by_1_T_124 & (prd_1 == 6'h3d));
			is_alloc_61 = (_alloc_by_0_T_124 & (prd_0 == 6'h3e)) | (_alloc_by_1_T_124 & (prd_1 == 6'h3e));
			is_alloc_62 = (_alloc_by_0_T_124 & (&prd_0)) | (_alloc_by_1_T_124 & (&prd_1));
			if (io_rbk_valid & |io_rbk_l_rd) begin
				if (~(|io_rbk_l_rd))
					rat_0 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h01)
					rat_1 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h02)
					rat_2 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h03)
					rat_3 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h04)
					rat_4 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h05)
					rat_5 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h06)
					rat_6 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h07)
					rat_7 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h08)
					rat_8 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h09)
					rat_9 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h0a)
					rat_10 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h0b)
					rat_11 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h0c)
					rat_12 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h0d)
					rat_13 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h0e)
					rat_14 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h0f)
					rat_15 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h10)
					rat_16 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h11)
					rat_17 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h12)
					rat_18 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h13)
					rat_19 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h14)
					rat_20 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h15)
					rat_21 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h16)
					rat_22 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h17)
					rat_23 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h18)
					rat_24 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h19)
					rat_25 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h1a)
					rat_26 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h1b)
					rat_27 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h1c)
					rat_28 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h1d)
					rat_29 <= io_rbk_stale_p_rd;
				if (io_rbk_l_rd == 5'h1e)
					rat_30 <= io_rbk_stale_p_rd;
				if (&io_rbk_l_rd)
					rat_31 <= io_rbk_stale_p_rd;
			end
			else if (fire) begin
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h00))
					rat_0 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h00))
					rat_0 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h01))
					rat_1 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h01))
					rat_1 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h02))
					rat_2 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h02))
					rat_2 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h03))
					rat_3 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h03))
					rat_3 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h04))
					rat_4 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h04))
					rat_4 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h05))
					rat_5 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h05))
					rat_5 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h06))
					rat_6 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h06))
					rat_6 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h07))
					rat_7 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h07))
					rat_7 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h08))
					rat_8 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h08))
					rat_8 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h09))
					rat_9 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h09))
					rat_9 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h0a))
					rat_10 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h0a))
					rat_10 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h0b))
					rat_11 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h0b))
					rat_11 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h0c))
					rat_12 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h0c))
					rat_12 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h0d))
					rat_13 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h0d))
					rat_13 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h0e))
					rat_14 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h0e))
					rat_14 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h0f))
					rat_15 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h0f))
					rat_15 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h10))
					rat_16 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h10))
					rat_16 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h11))
					rat_17 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h11))
					rat_17 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h12))
					rat_18 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h12))
					rat_18 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h13))
					rat_19 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h13))
					rat_19 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h14))
					rat_20 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h14))
					rat_20 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h15))
					rat_21 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h15))
					rat_21 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h16))
					rat_22 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h16))
					rat_22 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h17))
					rat_23 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h17))
					rat_23 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h18))
					rat_24 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h18))
					rat_24 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h19))
					rat_25 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h19))
					rat_25 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h1a))
					rat_26 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h1a))
					rat_26 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h1b))
					rat_27 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h1b))
					rat_27 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h1c))
					rat_28 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h1c))
					rat_28 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h1d))
					rat_29 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h1d))
					rat_29 <= prd_0;
				if (need_alloc_1 & (io_enq_bits_1_l_rd == 5'h1e))
					rat_30 <= prd_1;
				else if (need_alloc_0 & (io_enq_bits_0_l_rd == 5'h1e))
					rat_30 <= prd_0;
				if (need_alloc_1 & (&io_enq_bits_1_l_rd))
					rat_31 <= prd_1;
				else if (need_alloc_0 & (&io_enq_bits_0_l_rd))
					rat_31 <= prd_0;
			end
			busy_table_1 <= (is_rbk_free | is_alloc) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h01)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h01))) & busy_table_1);
			busy_table_2 <= (is_rbk_free_1 | is_alloc_1) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h02)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h02))) & busy_table_2);
			busy_table_3 <= (is_rbk_free_2 | is_alloc_2) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h03)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h03))) & busy_table_3);
			busy_table_4 <= (is_rbk_free_3 | is_alloc_3) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h04)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h04))) & busy_table_4);
			busy_table_5 <= (is_rbk_free_4 | is_alloc_4) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h05)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h05))) & busy_table_5);
			busy_table_6 <= (is_rbk_free_5 | is_alloc_5) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h06)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h06))) & busy_table_6);
			busy_table_7 <= (is_rbk_free_6 | is_alloc_6) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h07)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h07))) & busy_table_7);
			busy_table_8 <= (is_rbk_free_7 | is_alloc_7) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h08)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h08))) & busy_table_8);
			busy_table_9 <= (is_rbk_free_8 | is_alloc_8) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h09)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h09))) & busy_table_9);
			busy_table_10 <= (is_rbk_free_9 | is_alloc_9) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h0a)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h0a))) & busy_table_10);
			busy_table_11 <= (is_rbk_free_10 | is_alloc_10) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h0b)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h0b))) & busy_table_11);
			busy_table_12 <= (is_rbk_free_11 | is_alloc_11) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h0c)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h0c))) & busy_table_12);
			busy_table_13 <= (is_rbk_free_12 | is_alloc_12) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h0d)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h0d))) & busy_table_13);
			busy_table_14 <= (is_rbk_free_13 | is_alloc_13) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h0e)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h0e))) & busy_table_14);
			busy_table_15 <= (is_rbk_free_14 | is_alloc_14) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h0f)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h0f))) & busy_table_15);
			busy_table_16 <= (is_rbk_free_15 | is_alloc_15) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h10)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h10))) & busy_table_16);
			busy_table_17 <= (is_rbk_free_16 | is_alloc_16) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h11)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h11))) & busy_table_17);
			busy_table_18 <= (is_rbk_free_17 | is_alloc_17) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h12)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h12))) & busy_table_18);
			busy_table_19 <= (is_rbk_free_18 | is_alloc_18) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h13)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h13))) & busy_table_19);
			busy_table_20 <= (is_rbk_free_19 | is_alloc_19) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h14)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h14))) & busy_table_20);
			busy_table_21 <= (is_rbk_free_20 | is_alloc_20) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h15)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h15))) & busy_table_21);
			busy_table_22 <= (is_rbk_free_21 | is_alloc_21) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h16)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h16))) & busy_table_22);
			busy_table_23 <= (is_rbk_free_22 | is_alloc_22) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h17)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h17))) & busy_table_23);
			busy_table_24 <= (is_rbk_free_23 | is_alloc_23) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h18)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h18))) & busy_table_24);
			busy_table_25 <= (is_rbk_free_24 | is_alloc_24) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h19)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h19))) & busy_table_25);
			busy_table_26 <= (is_rbk_free_25 | is_alloc_25) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h1a)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h1a))) & busy_table_26);
			busy_table_27 <= (is_rbk_free_26 | is_alloc_26) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h1b)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h1b))) & busy_table_27);
			busy_table_28 <= (is_rbk_free_27 | is_alloc_27) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h1c)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h1c))) & busy_table_28);
			busy_table_29 <= (is_rbk_free_28 | is_alloc_28) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h1d)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h1d))) & busy_table_29);
			busy_table_30 <= (is_rbk_free_29 | is_alloc_29) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h1e)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h1e))) & busy_table_30);
			busy_table_31 <= (is_rbk_free_30 | is_alloc_30) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h1f)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h1f))) & busy_table_31);
			busy_table_32 <= (is_rbk_free_31 | is_alloc_31) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h20)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h20))) & busy_table_32);
			busy_table_33 <= (is_rbk_free_32 | is_alloc_32) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h21)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h21))) & busy_table_33);
			busy_table_34 <= (is_rbk_free_33 | is_alloc_33) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h22)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h22))) & busy_table_34);
			busy_table_35 <= (is_rbk_free_34 | is_alloc_34) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h23)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h23))) & busy_table_35);
			busy_table_36 <= (is_rbk_free_35 | is_alloc_35) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h24)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h24))) & busy_table_36);
			busy_table_37 <= (is_rbk_free_36 | is_alloc_36) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h25)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h25))) & busy_table_37);
			busy_table_38 <= (is_rbk_free_37 | is_alloc_37) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h26)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h26))) & busy_table_38);
			busy_table_39 <= (is_rbk_free_38 | is_alloc_38) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h27)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h27))) & busy_table_39);
			busy_table_40 <= (is_rbk_free_39 | is_alloc_39) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h28)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h28))) & busy_table_40);
			busy_table_41 <= (is_rbk_free_40 | is_alloc_40) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h29)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h29))) & busy_table_41);
			busy_table_42 <= (is_rbk_free_41 | is_alloc_41) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h2a)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h2a))) & busy_table_42);
			busy_table_43 <= (is_rbk_free_42 | is_alloc_42) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h2b)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h2b))) & busy_table_43);
			busy_table_44 <= (is_rbk_free_43 | is_alloc_43) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h2c)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h2c))) & busy_table_44);
			busy_table_45 <= (is_rbk_free_44 | is_alloc_44) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h2d)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h2d))) & busy_table_45);
			busy_table_46 <= (is_rbk_free_45 | is_alloc_45) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h2e)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h2e))) & busy_table_46);
			busy_table_47 <= (is_rbk_free_46 | is_alloc_46) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h2f)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h2f))) & busy_table_47);
			busy_table_48 <= (is_rbk_free_47 | is_alloc_47) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h30)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h30))) & busy_table_48);
			busy_table_49 <= (is_rbk_free_48 | is_alloc_48) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h31)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h31))) & busy_table_49);
			busy_table_50 <= (is_rbk_free_49 | is_alloc_49) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h32)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h32))) & busy_table_50);
			busy_table_51 <= (is_rbk_free_50 | is_alloc_50) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h33)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h33))) & busy_table_51);
			busy_table_52 <= (is_rbk_free_51 | is_alloc_51) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h34)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h34))) & busy_table_52);
			busy_table_53 <= (is_rbk_free_52 | is_alloc_52) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h35)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h35))) & busy_table_53);
			busy_table_54 <= (is_rbk_free_53 | is_alloc_53) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h36)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h36))) & busy_table_54);
			busy_table_55 <= (is_rbk_free_54 | is_alloc_54) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h37)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h37))) & busy_table_55);
			busy_table_56 <= (is_rbk_free_55 | is_alloc_55) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h38)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h38))) & busy_table_56);
			busy_table_57 <= (is_rbk_free_56 | is_alloc_56) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h39)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h39))) & busy_table_57);
			busy_table_58 <= (is_rbk_free_57 | is_alloc_57) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h3a)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h3a))) & busy_table_58);
			busy_table_59 <= (is_rbk_free_58 | is_alloc_58) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h3b)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h3b))) & busy_table_59);
			busy_table_60 <= (is_rbk_free_59 | is_alloc_59) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h3c)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h3c))) & busy_table_60);
			busy_table_61 <= (is_rbk_free_60 | is_alloc_60) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h3d)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h3d))) & busy_table_61);
			busy_table_62 <= (is_rbk_free_61 | is_alloc_61) | (~((io_cdb_0_valid & (io_cdb_0_bits_p_rd == 6'h3e)) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == 6'h3e))) & busy_table_62);
			busy_table_63 <= (is_rbk_free_62 | is_alloc_62) | (~((io_cdb_0_valid & (&io_cdb_0_bits_p_rd)) | (io_cdb_1_valid & (&io_cdb_1_bits_p_rd))) & busy_table_63);
			is_free_1 <= is_rbk_free | (~is_alloc & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h01)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h01))) | is_free_1));
			is_free_2 <= is_rbk_free_1 | (~is_alloc_1 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h02)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h02))) | is_free_2));
			is_free_3 <= is_rbk_free_2 | (~is_alloc_2 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h03)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h03))) | is_free_3));
			is_free_4 <= is_rbk_free_3 | (~is_alloc_3 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h04)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h04))) | is_free_4));
			is_free_5 <= is_rbk_free_4 | (~is_alloc_4 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h05)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h05))) | is_free_5));
			is_free_6 <= is_rbk_free_5 | (~is_alloc_5 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h06)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h06))) | is_free_6));
			is_free_7 <= is_rbk_free_6 | (~is_alloc_6 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h07)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h07))) | is_free_7));
			is_free_8 <= is_rbk_free_7 | (~is_alloc_7 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h08)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h08))) | is_free_8));
			is_free_9 <= is_rbk_free_8 | (~is_alloc_8 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h09)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h09))) | is_free_9));
			is_free_10 <= is_rbk_free_9 | (~is_alloc_9 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h0a)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h0a))) | is_free_10));
			is_free_11 <= is_rbk_free_10 | (~is_alloc_10 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h0b)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h0b))) | is_free_11));
			is_free_12 <= is_rbk_free_11 | (~is_alloc_11 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h0c)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h0c))) | is_free_12));
			is_free_13 <= is_rbk_free_12 | (~is_alloc_12 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h0d)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h0d))) | is_free_13));
			is_free_14 <= is_rbk_free_13 | (~is_alloc_13 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h0e)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h0e))) | is_free_14));
			is_free_15 <= is_rbk_free_14 | (~is_alloc_14 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h0f)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h0f))) | is_free_15));
			is_free_16 <= is_rbk_free_15 | (~is_alloc_15 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h10)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h10))) | is_free_16));
			is_free_17 <= is_rbk_free_16 | (~is_alloc_16 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h11)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h11))) | is_free_17));
			is_free_18 <= is_rbk_free_17 | (~is_alloc_17 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h12)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h12))) | is_free_18));
			is_free_19 <= is_rbk_free_18 | (~is_alloc_18 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h13)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h13))) | is_free_19));
			is_free_20 <= is_rbk_free_19 | (~is_alloc_19 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h14)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h14))) | is_free_20));
			is_free_21 <= is_rbk_free_20 | (~is_alloc_20 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h15)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h15))) | is_free_21));
			is_free_22 <= is_rbk_free_21 | (~is_alloc_21 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h16)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h16))) | is_free_22));
			is_free_23 <= is_rbk_free_22 | (~is_alloc_22 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h17)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h17))) | is_free_23));
			is_free_24 <= is_rbk_free_23 | (~is_alloc_23 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h18)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h18))) | is_free_24));
			is_free_25 <= is_rbk_free_24 | (~is_alloc_24 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h19)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h19))) | is_free_25));
			is_free_26 <= is_rbk_free_25 | (~is_alloc_25 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h1a)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h1a))) | is_free_26));
			is_free_27 <= is_rbk_free_26 | (~is_alloc_26 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h1b)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h1b))) | is_free_27));
			is_free_28 <= is_rbk_free_27 | (~is_alloc_27 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h1c)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h1c))) | is_free_28));
			is_free_29 <= is_rbk_free_28 | (~is_alloc_28 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h1d)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h1d))) | is_free_29));
			is_free_30 <= is_rbk_free_29 | (~is_alloc_29 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h1e)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h1e))) | is_free_30));
			is_free_31 <= is_rbk_free_30 | (~is_alloc_30 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h1f)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h1f))) | is_free_31));
			is_free_32 <= is_rbk_free_31 | (~is_alloc_31 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h20)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h20))) | is_free_32));
			is_free_33 <= is_rbk_free_32 | (~is_alloc_32 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h21)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h21))) | is_free_33));
			is_free_34 <= is_rbk_free_33 | (~is_alloc_33 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h22)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h22))) | is_free_34));
			is_free_35 <= is_rbk_free_34 | (~is_alloc_34 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h23)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h23))) | is_free_35));
			is_free_36 <= is_rbk_free_35 | (~is_alloc_35 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h24)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h24))) | is_free_36));
			is_free_37 <= is_rbk_free_36 | (~is_alloc_36 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h25)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h25))) | is_free_37));
			is_free_38 <= is_rbk_free_37 | (~is_alloc_37 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h26)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h26))) | is_free_38));
			is_free_39 <= is_rbk_free_38 | (~is_alloc_38 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h27)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h27))) | is_free_39));
			is_free_40 <= is_rbk_free_39 | (~is_alloc_39 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h28)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h28))) | is_free_40));
			is_free_41 <= is_rbk_free_40 | (~is_alloc_40 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h29)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h29))) | is_free_41));
			is_free_42 <= is_rbk_free_41 | (~is_alloc_41 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h2a)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h2a))) | is_free_42));
			is_free_43 <= is_rbk_free_42 | (~is_alloc_42 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h2b)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h2b))) | is_free_43));
			is_free_44 <= is_rbk_free_43 | (~is_alloc_43 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h2c)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h2c))) | is_free_44));
			is_free_45 <= is_rbk_free_44 | (~is_alloc_44 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h2d)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h2d))) | is_free_45));
			is_free_46 <= is_rbk_free_45 | (~is_alloc_45 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h2e)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h2e))) | is_free_46));
			is_free_47 <= is_rbk_free_46 | (~is_alloc_46 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h2f)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h2f))) | is_free_47));
			is_free_48 <= is_rbk_free_47 | (~is_alloc_47 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h30)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h30))) | is_free_48));
			is_free_49 <= is_rbk_free_48 | (~is_alloc_48 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h31)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h31))) | is_free_49));
			is_free_50 <= is_rbk_free_49 | (~is_alloc_49 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h32)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h32))) | is_free_50));
			is_free_51 <= is_rbk_free_50 | (~is_alloc_50 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h33)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h33))) | is_free_51));
			is_free_52 <= is_rbk_free_51 | (~is_alloc_51 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h34)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h34))) | is_free_52));
			is_free_53 <= is_rbk_free_52 | (~is_alloc_52 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h35)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h35))) | is_free_53));
			is_free_54 <= is_rbk_free_53 | (~is_alloc_53 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h36)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h36))) | is_free_54));
			is_free_55 <= is_rbk_free_54 | (~is_alloc_54 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h37)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h37))) | is_free_55));
			is_free_56 <= is_rbk_free_55 | (~is_alloc_55 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h38)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h38))) | is_free_56));
			is_free_57 <= is_rbk_free_56 | (~is_alloc_56 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h39)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h39))) | is_free_57));
			is_free_58 <= is_rbk_free_57 | (~is_alloc_57 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h3a)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h3a))) | is_free_58));
			is_free_59 <= is_rbk_free_58 | (~is_alloc_58 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h3b)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h3b))) | is_free_59));
			is_free_60 <= is_rbk_free_59 | (~is_alloc_59 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h3c)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h3c))) | is_free_60));
			is_free_61 <= is_rbk_free_60 | (~is_alloc_60 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h3d)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h3d))) | is_free_61));
			is_free_62 <= is_rbk_free_61 | (~is_alloc_61 & (((io_commit_free_0_valid & (io_commit_free_0_bits == 6'h3e)) | (io_commit_free_1_valid & (io_commit_free_1_bits == 6'h3e))) | is_free_62));
			is_free_63 <= is_rbk_free_62 | (~is_alloc_62 & (((io_commit_free_0_valid & (&io_commit_free_0_bits)) | (io_commit_free_1_valid & (&io_commit_free_1_bits))) | is_free_63));
		end
	assign io_enq_ready = (io_deq_ready & can_alloc) & ~io_rbk_active;
	assign io_deq_valid = (io_enq_valid & can_alloc) & ~io_rbk_active;
	assign io_deq_bits_0_valid = io_enq_bits_0_valid;
	assign io_deq_bits_0_pc = io_enq_bits_0_pc;
	assign io_deq_bits_0_inst = io_enq_bits_0_inst;
	assign io_deq_bits_0_fu_code = io_enq_bits_0_fu_code;
	assign io_deq_bits_0_alu_op = io_enq_bits_0_alu_op;
	assign io_deq_bits_0_op1_sel = io_enq_bits_0_op1_sel;
	assign io_deq_bits_0_op2_sel = io_enq_bits_0_op2_sel;
	assign io_deq_bits_0_imm = io_enq_bits_0_imm;
	assign io_deq_bits_0_imm_sel = io_enq_bits_0_imm_sel;
	assign io_deq_bits_0_is_w = io_enq_bits_0_is_w;
	assign io_deq_bits_0_mem_cmd = io_enq_bits_0_mem_cmd;
	assign io_deq_bits_0_mem_size = io_enq_bits_0_mem_size;
	assign io_deq_bits_0_mem_signed = io_enq_bits_0_mem_signed;
	assign io_deq_bits_0_br_type = io_enq_bits_0_br_type;
	assign io_deq_bits_0_l_rd = io_enq_bits_0_l_rd;
	assign io_deq_bits_0_l_rs1 = io_enq_bits_0_l_rs1;
	assign io_deq_bits_0_l_rs2 = io_enq_bits_0_l_rs2;
	assign io_deq_bits_0_rf_wen = io_enq_bits_0_rf_wen;
	assign io_deq_bits_0_use_rs1 = io_enq_bits_0_use_rs1;
	assign io_deq_bits_0_use_rs2 = io_enq_bits_0_use_rs2;
	assign io_deq_bits_0_p_rd = prd_0;
	assign io_deq_bits_0_p_rs1 = _GEN[io_enq_bits_0_l_rs1 * 6+:6];
	assign io_deq_bits_0_p_rs2 = _GEN[io_enq_bits_0_l_rs2 * 6+:6];
	assign io_deq_bits_0_prs1_ready = ((~io_enq_bits_0_use_rs1 | ~_GEN_0[_GEN[io_enq_bits_0_l_rs1 * 6+:6]]) | (io_cdb_0_valid & (io_cdb_0_bits_p_rd == _GEN[io_enq_bits_0_l_rs1 * 6+:6]))) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == _GEN[io_enq_bits_0_l_rs1 * 6+:6]));
	assign io_deq_bits_0_prs2_ready = ((~io_enq_bits_0_use_rs2 | ~_GEN_0[_GEN[io_enq_bits_0_l_rs2 * 6+:6]]) | (io_cdb_0_valid & (io_cdb_0_bits_p_rd == _GEN[io_enq_bits_0_l_rs2 * 6+:6]))) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == _GEN[io_enq_bits_0_l_rs2 * 6+:6]));
	assign io_deq_bits_0_stale_p_rd = _GEN[io_enq_bits_0_l_rd * 6+:6];
	assign io_deq_bits_0_exception = io_enq_bits_0_exception;
	assign io_deq_bits_0_pred_taken = io_enq_bits_0_pred_taken;
	assign io_deq_bits_0_pred_target = io_enq_bits_0_pred_target;
	assign io_deq_bits_1_valid = io_enq_bits_1_valid;
	assign io_deq_bits_1_pc = io_enq_bits_1_pc;
	assign io_deq_bits_1_inst = io_enq_bits_1_inst;
	assign io_deq_bits_1_fu_code = io_enq_bits_1_fu_code;
	assign io_deq_bits_1_alu_op = io_enq_bits_1_alu_op;
	assign io_deq_bits_1_op1_sel = io_enq_bits_1_op1_sel;
	assign io_deq_bits_1_op2_sel = io_enq_bits_1_op2_sel;
	assign io_deq_bits_1_imm = io_enq_bits_1_imm;
	assign io_deq_bits_1_imm_sel = io_enq_bits_1_imm_sel;
	assign io_deq_bits_1_is_w = io_enq_bits_1_is_w;
	assign io_deq_bits_1_mem_cmd = io_enq_bits_1_mem_cmd;
	assign io_deq_bits_1_mem_size = io_enq_bits_1_mem_size;
	assign io_deq_bits_1_mem_signed = io_enq_bits_1_mem_signed;
	assign io_deq_bits_1_br_type = io_enq_bits_1_br_type;
	assign io_deq_bits_1_l_rd = io_enq_bits_1_l_rd;
	assign io_deq_bits_1_l_rs1 = io_enq_bits_1_l_rs1;
	assign io_deq_bits_1_l_rs2 = io_enq_bits_1_l_rs2;
	assign io_deq_bits_1_rf_wen = io_enq_bits_1_rf_wen;
	assign io_deq_bits_1_use_rs1 = io_enq_bits_1_use_rs1;
	assign io_deq_bits_1_use_rs2 = io_enq_bits_1_use_rs2;
	assign io_deq_bits_1_p_rd = prd_1;
	assign io_deq_bits_1_p_rs1 = (dep1_rs1_on_0 ? prd_0 : _GEN[io_enq_bits_1_l_rs1 * 6+:6]);
	assign io_deq_bits_1_p_rs2 = (dep1_rs2_on_0 ? prd_0 : _GEN[io_enq_bits_1_l_rs2 * 6+:6]);
	assign io_deq_bits_1_prs1_ready = ~io_enq_bits_1_use_rs1 | (~dep1_rs1_on_0 & ((~_GEN_0[_GEN[io_enq_bits_1_l_rs1 * 6+:6]] | (io_cdb_0_valid & (io_cdb_0_bits_p_rd == _GEN[io_enq_bits_1_l_rs1 * 6+:6]))) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == _GEN[io_enq_bits_1_l_rs1 * 6+:6]))));
	assign io_deq_bits_1_prs2_ready = ~io_enq_bits_1_use_rs2 | (~dep1_rs2_on_0 & ((~_GEN_0[_GEN[io_enq_bits_1_l_rs2 * 6+:6]] | (io_cdb_0_valid & (io_cdb_0_bits_p_rd == _GEN[io_enq_bits_1_l_rs2 * 6+:6]))) | (io_cdb_1_valid & (io_cdb_1_bits_p_rd == _GEN[io_enq_bits_1_l_rs2 * 6+:6]))));
	assign io_deq_bits_1_stale_p_rd = ((need_2 & (io_enq_bits_0_l_rd == io_enq_bits_1_l_rd)) & |io_enq_bits_1_l_rd ? prd_0 : _GEN[io_enq_bits_1_l_rd * 6+:6]);
	assign io_deq_bits_1_exception = io_enq_bits_1_exception;
	assign io_deq_bits_1_pred_taken = io_enq_bits_1_pred_taken;
	assign io_deq_bits_1_pred_target = io_enq_bits_1_pred_target;
endmodule
module Rob (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_0_valid,
	io_enq_bits_0_inst,
	io_enq_bits_0_mem_cmd,
	io_enq_bits_0_l_rd,
	io_enq_bits_0_rf_wen,
	io_enq_bits_0_p_rd,
	io_enq_bits_0_stale_p_rd,
	io_enq_bits_0_exception,
	io_enq_bits_1_valid,
	io_enq_bits_1_inst,
	io_enq_bits_1_mem_cmd,
	io_enq_bits_1_l_rd,
	io_enq_bits_1_rf_wen,
	io_enq_bits_1_p_rd,
	io_enq_bits_1_stale_p_rd,
	io_enq_bits_1_exception,
	io_rob_idx_alloc_0,
	io_rob_idx_alloc_1,
	io_cdb_0_valid,
	io_cdb_0_bits_rob_idx,
	io_cdb_0_bits_exc,
	io_cdb_0_bits_is_branch,
	io_cdb_0_bits_br_taken,
	io_cdb_0_bits_br_target,
	io_cdb_0_bits_br_pc,
	io_cdb_1_valid,
	io_cdb_1_bits_rob_idx,
	io_cdb_1_bits_exc,
	io_commit_free_0_valid,
	io_commit_free_0_bits,
	io_commit_free_1_valid,
	io_commit_free_1_bits,
	io_flush_pipeline,
	io_commit_store_0_valid,
	io_commit_store_0_bits,
	io_commit_store_1_valid,
	io_commit_store_1_bits,
	io_br_res_valid,
	io_br_res_bits_mispredicted,
	io_br_res_bits_rob_idx,
	io_rbk_active,
	io_rbk_valid,
	io_rbk_l_rd,
	io_rbk_p_rd,
	io_rbk_stale_p_rd,
	io_rob_head_idx,
	io_commit_num,
	io_bpu_update_valid,
	io_bpu_update_bits_pc,
	io_bpu_update_bits_target,
	io_bpu_update_bits_taken
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_enq_bits_0_valid;
	input [31:0] io_enq_bits_0_inst;
	input [2:0] io_enq_bits_0_mem_cmd;
	input [4:0] io_enq_bits_0_l_rd;
	input io_enq_bits_0_rf_wen;
	input [5:0] io_enq_bits_0_p_rd;
	input [5:0] io_enq_bits_0_stale_p_rd;
	input io_enq_bits_0_exception;
	input io_enq_bits_1_valid;
	input [31:0] io_enq_bits_1_inst;
	input [2:0] io_enq_bits_1_mem_cmd;
	input [4:0] io_enq_bits_1_l_rd;
	input io_enq_bits_1_rf_wen;
	input [5:0] io_enq_bits_1_p_rd;
	input [5:0] io_enq_bits_1_stale_p_rd;
	input io_enq_bits_1_exception;
	output wire [3:0] io_rob_idx_alloc_0;
	output wire [3:0] io_rob_idx_alloc_1;
	input io_cdb_0_valid;
	input [3:0] io_cdb_0_bits_rob_idx;
	input io_cdb_0_bits_exc;
	input io_cdb_0_bits_is_branch;
	input io_cdb_0_bits_br_taken;
	input [63:0] io_cdb_0_bits_br_target;
	input [63:0] io_cdb_0_bits_br_pc;
	input io_cdb_1_valid;
	input [3:0] io_cdb_1_bits_rob_idx;
	input io_cdb_1_bits_exc;
	output wire io_commit_free_0_valid;
	output wire [5:0] io_commit_free_0_bits;
	output wire io_commit_free_1_valid;
	output wire [5:0] io_commit_free_1_bits;
	output wire io_flush_pipeline;
	output wire io_commit_store_0_valid;
	output wire [3:0] io_commit_store_0_bits;
	output wire io_commit_store_1_valid;
	output wire [3:0] io_commit_store_1_bits;
	input io_br_res_valid;
	input io_br_res_bits_mispredicted;
	input [3:0] io_br_res_bits_rob_idx;
	output wire io_rbk_active;
	output wire io_rbk_valid;
	output wire [4:0] io_rbk_l_rd;
	output wire [5:0] io_rbk_p_rd;
	output wire [5:0] io_rbk_stale_p_rd;
	output wire [3:0] io_rob_head_idx;
	output wire [1:0] io_commit_num;
	output wire io_bpu_update_valid;
	output wire [63:0] io_bpu_update_bits_pc;
	output wire [63:0] io_bpu_update_bits_target;
	output wire io_bpu_update_bits_taken;
	reg rob_busy_0;
	reg rob_busy_1;
	reg rob_busy_2;
	reg rob_busy_3;
	reg rob_busy_4;
	reg rob_busy_5;
	reg rob_busy_6;
	reg rob_busy_7;
	reg rob_busy_8;
	reg rob_busy_9;
	reg rob_busy_10;
	reg rob_busy_11;
	reg rob_busy_12;
	reg rob_busy_13;
	reg rob_busy_14;
	reg rob_busy_15;
	reg rob_complete_0;
	reg rob_complete_1;
	reg rob_complete_2;
	reg rob_complete_3;
	reg rob_complete_4;
	reg rob_complete_5;
	reg rob_complete_6;
	reg rob_complete_7;
	reg rob_complete_8;
	reg rob_complete_9;
	reg rob_complete_10;
	reg rob_complete_11;
	reg rob_complete_12;
	reg rob_complete_13;
	reg rob_complete_14;
	reg rob_complete_15;
	reg rob_exc_0;
	reg rob_exc_1;
	reg rob_exc_2;
	reg rob_exc_3;
	reg rob_exc_4;
	reg rob_exc_5;
	reg rob_exc_6;
	reg rob_exc_7;
	reg rob_exc_8;
	reg rob_exc_9;
	reg rob_exc_10;
	reg rob_exc_11;
	reg rob_exc_12;
	reg rob_exc_13;
	reg rob_exc_14;
	reg rob_exc_15;
	reg rob_rf_wen_0;
	reg rob_rf_wen_1;
	reg rob_rf_wen_2;
	reg rob_rf_wen_3;
	reg rob_rf_wen_4;
	reg rob_rf_wen_5;
	reg rob_rf_wen_6;
	reg rob_rf_wen_7;
	reg rob_rf_wen_8;
	reg rob_rf_wen_9;
	reg rob_rf_wen_10;
	reg rob_rf_wen_11;
	reg rob_rf_wen_12;
	reg rob_rf_wen_13;
	reg rob_rf_wen_14;
	reg rob_rf_wen_15;
	reg rob_is_store_0;
	reg rob_is_store_1;
	reg rob_is_store_2;
	reg rob_is_store_3;
	reg rob_is_store_4;
	reg rob_is_store_5;
	reg rob_is_store_6;
	reg rob_is_store_7;
	reg rob_is_store_8;
	reg rob_is_store_9;
	reg rob_is_store_10;
	reg rob_is_store_11;
	reg rob_is_store_12;
	reg rob_is_store_13;
	reg rob_is_store_14;
	reg rob_is_store_15;
	reg [5:0] rob_stale_p_rd_0;
	reg [5:0] rob_stale_p_rd_1;
	reg [5:0] rob_stale_p_rd_2;
	reg [5:0] rob_stale_p_rd_3;
	reg [5:0] rob_stale_p_rd_4;
	reg [5:0] rob_stale_p_rd_5;
	reg [5:0] rob_stale_p_rd_6;
	reg [5:0] rob_stale_p_rd_7;
	reg [5:0] rob_stale_p_rd_8;
	reg [5:0] rob_stale_p_rd_9;
	reg [5:0] rob_stale_p_rd_10;
	reg [5:0] rob_stale_p_rd_11;
	reg [5:0] rob_stale_p_rd_12;
	reg [5:0] rob_stale_p_rd_13;
	reg [5:0] rob_stale_p_rd_14;
	reg [5:0] rob_stale_p_rd_15;
	reg [4:0] rob_l_rd_0;
	reg [4:0] rob_l_rd_1;
	reg [4:0] rob_l_rd_2;
	reg [4:0] rob_l_rd_3;
	reg [4:0] rob_l_rd_4;
	reg [4:0] rob_l_rd_5;
	reg [4:0] rob_l_rd_6;
	reg [4:0] rob_l_rd_7;
	reg [4:0] rob_l_rd_8;
	reg [4:0] rob_l_rd_9;
	reg [4:0] rob_l_rd_10;
	reg [4:0] rob_l_rd_11;
	reg [4:0] rob_l_rd_12;
	reg [4:0] rob_l_rd_13;
	reg [4:0] rob_l_rd_14;
	reg [4:0] rob_l_rd_15;
	reg [5:0] rob_p_rd_0;
	reg [5:0] rob_p_rd_1;
	reg [5:0] rob_p_rd_2;
	reg [5:0] rob_p_rd_3;
	reg [5:0] rob_p_rd_4;
	reg [5:0] rob_p_rd_5;
	reg [5:0] rob_p_rd_6;
	reg [5:0] rob_p_rd_7;
	reg [5:0] rob_p_rd_8;
	reg [5:0] rob_p_rd_9;
	reg [5:0] rob_p_rd_10;
	reg [5:0] rob_p_rd_11;
	reg [5:0] rob_p_rd_12;
	reg [5:0] rob_p_rd_13;
	reg [5:0] rob_p_rd_14;
	reg [5:0] rob_p_rd_15;
	reg [4:0] head;
	reg [4:0] tail;
	reg rob_is_branch_0;
	reg rob_is_branch_1;
	reg rob_is_branch_2;
	reg rob_is_branch_3;
	reg rob_is_branch_4;
	reg rob_is_branch_5;
	reg rob_is_branch_6;
	reg rob_is_branch_7;
	reg rob_is_branch_8;
	reg rob_is_branch_9;
	reg rob_is_branch_10;
	reg rob_is_branch_11;
	reg rob_is_branch_12;
	reg rob_is_branch_13;
	reg rob_is_branch_14;
	reg rob_is_branch_15;
	reg rob_br_taken_0;
	reg rob_br_taken_1;
	reg rob_br_taken_2;
	reg rob_br_taken_3;
	reg rob_br_taken_4;
	reg rob_br_taken_5;
	reg rob_br_taken_6;
	reg rob_br_taken_7;
	reg rob_br_taken_8;
	reg rob_br_taken_9;
	reg rob_br_taken_10;
	reg rob_br_taken_11;
	reg rob_br_taken_12;
	reg rob_br_taken_13;
	reg rob_br_taken_14;
	reg rob_br_taken_15;
	reg [63:0] rob_br_target_0;
	reg [63:0] rob_br_target_1;
	reg [63:0] rob_br_target_2;
	reg [63:0] rob_br_target_3;
	reg [63:0] rob_br_target_4;
	reg [63:0] rob_br_target_5;
	reg [63:0] rob_br_target_6;
	reg [63:0] rob_br_target_7;
	reg [63:0] rob_br_target_8;
	reg [63:0] rob_br_target_9;
	reg [63:0] rob_br_target_10;
	reg [63:0] rob_br_target_11;
	reg [63:0] rob_br_target_12;
	reg [63:0] rob_br_target_13;
	reg [63:0] rob_br_target_14;
	reg [63:0] rob_br_target_15;
	reg [63:0] rob_br_pc_0;
	reg [63:0] rob_br_pc_1;
	reg [63:0] rob_br_pc_2;
	reg [63:0] rob_br_pc_3;
	reg [63:0] rob_br_pc_4;
	reg [63:0] rob_br_pc_5;
	reg [63:0] rob_br_pc_6;
	reg [63:0] rob_br_pc_7;
	reg [63:0] rob_br_pc_8;
	reg [63:0] rob_br_pc_9;
	reg [63:0] rob_br_pc_10;
	reg [63:0] rob_br_pc_11;
	reg [63:0] rob_br_pc_12;
	reg [63:0] rob_br_pc_13;
	reg [63:0] rob_br_pc_14;
	reg [63:0] rob_br_pc_15;
	reg state;
	reg [4:0] walk_ptr;
	reg [4:0] target_ptr;
	wire [15:0] _GEN = {rob_rf_wen_15, rob_rf_wen_14, rob_rf_wen_13, rob_rf_wen_12, rob_rf_wen_11, rob_rf_wen_10, rob_rf_wen_9, rob_rf_wen_8, rob_rf_wen_7, rob_rf_wen_6, rob_rf_wen_5, rob_rf_wen_4, rob_rf_wen_3, rob_rf_wen_2, rob_rf_wen_1, rob_rf_wen_0};
	wire _is_rbk_clear_T_45 = walk_ptr != target_ptr;
	wire [79:0] _GEN_0 = {rob_l_rd_15, rob_l_rd_14, rob_l_rd_13, rob_l_rd_12, rob_l_rd_11, rob_l_rd_10, rob_l_rd_9, rob_l_rd_8, rob_l_rd_7, rob_l_rd_6, rob_l_rd_5, rob_l_rd_4, rob_l_rd_3, rob_l_rd_2, rob_l_rd_1, rob_l_rd_0};
	wire [95:0] _GEN_1 = {rob_p_rd_15, rob_p_rd_14, rob_p_rd_13, rob_p_rd_12, rob_p_rd_11, rob_p_rd_10, rob_p_rd_9, rob_p_rd_8, rob_p_rd_7, rob_p_rd_6, rob_p_rd_5, rob_p_rd_4, rob_p_rd_3, rob_p_rd_2, rob_p_rd_1, rob_p_rd_0};
	wire [95:0] _GEN_2 = {rob_stale_p_rd_15, rob_stale_p_rd_14, rob_stale_p_rd_13, rob_stale_p_rd_12, rob_stale_p_rd_11, rob_stale_p_rd_10, rob_stale_p_rd_9, rob_stale_p_rd_8, rob_stale_p_rd_7, rob_stale_p_rd_6, rob_stale_p_rd_5, rob_stale_p_rd_4, rob_stale_p_rd_3, rob_stale_p_rd_2, rob_stale_p_rd_1, rob_stale_p_rd_0};
	wire [3:0] _head_1_sum_T = head[3:0] + 4'h1;
	wire [15:0] _GEN_3 = {rob_busy_15, rob_busy_14, rob_busy_13, rob_busy_12, rob_busy_11, rob_busy_10, rob_busy_9, rob_busy_8, rob_busy_7, rob_busy_6, rob_busy_5, rob_busy_4, rob_busy_3, rob_busy_2, rob_busy_1, rob_busy_0};
	wire [15:0] _GEN_4 = {rob_complete_15, rob_complete_14, rob_complete_13, rob_complete_12, rob_complete_11, rob_complete_10, rob_complete_9, rob_complete_8, rob_complete_7, rob_complete_6, rob_complete_5, rob_complete_4, rob_complete_3, rob_complete_2, rob_complete_1, rob_complete_0};
	wire can_commit_0 = _GEN_3[head[3:0]] & _GEN_4[head[3:0]];
	wire [15:0] _GEN_5 = {rob_exc_15, rob_exc_14, rob_exc_13, rob_exc_12, rob_exc_11, rob_exc_10, rob_exc_9, rob_exc_8, rob_exc_7, rob_exc_6, rob_exc_5, rob_exc_4, rob_exc_3, rob_exc_2, rob_exc_1, rob_exc_0};
	wire _GEN_6 = _GEN_5[head[3:0]];
	wire can_commit_1 = ((can_commit_0 & ~_GEN_6) & _GEN_3[_head_1_sum_T]) & _GEN_4[_head_1_sum_T];
	wire _GEN_7 = can_commit_0 & _GEN_6;
	wire _GEN_8 = can_commit_1 & _GEN_5[_head_1_sum_T];
	wire [1:0] commit_count = ((state | _GEN_7) | _GEN_8 ? 2'h0 : (can_commit_1 ? 2'h2 : {1'h0, can_commit_0}));
	wire [4:0] _GEN_9 = {3'h0, commit_count};
	wire io_enq_ready_0 = (((tail - head) - _GEN_9) < 5'h0f) & ~state;
	wire [3:0] _tail_1_sum_T = tail[3:0] + 4'h1;
	reg [31:0] debug_rob_inst_0;
	reg [31:0] debug_rob_inst_1;
	reg [31:0] debug_rob_inst_2;
	reg [31:0] debug_rob_inst_3;
	reg [31:0] debug_rob_inst_4;
	reg [31:0] debug_rob_inst_5;
	reg [31:0] debug_rob_inst_6;
	reg [31:0] debug_rob_inst_7;
	reg [31:0] debug_rob_inst_8;
	reg [31:0] debug_rob_inst_9;
	reg [31:0] debug_rob_inst_10;
	reg [31:0] debug_rob_inst_11;
	reg [31:0] debug_rob_inst_12;
	reg [31:0] debug_rob_inst_13;
	reg [31:0] debug_rob_inst_14;
	reg [31:0] debug_rob_inst_15;
	wire cmt1_fire = commit_count == 2'h2;
	wire [5:0] io_commit_free_0_bits_0 = _GEN_2[head[3:0] * 6+:6];
	wire [15:0] _GEN_10 = {rob_is_store_15, rob_is_store_14, rob_is_store_13, rob_is_store_12, rob_is_store_11, rob_is_store_10, rob_is_store_9, rob_is_store_8, rob_is_store_7, rob_is_store_6, rob_is_store_5, rob_is_store_4, rob_is_store_3, rob_is_store_2, rob_is_store_1, rob_is_store_0};
	wire [15:0] _GEN_11 = {rob_is_branch_15, rob_is_branch_14, rob_is_branch_13, rob_is_branch_12, rob_is_branch_11, rob_is_branch_10, rob_is_branch_9, rob_is_branch_8, rob_is_branch_7, rob_is_branch_6, rob_is_branch_5, rob_is_branch_4, rob_is_branch_3, rob_is_branch_2, rob_is_branch_1, rob_is_branch_0};
	wire [15:0] _GEN_12 = {rob_br_taken_15, rob_br_taken_14, rob_br_taken_13, rob_br_taken_12, rob_br_taken_11, rob_br_taken_10, rob_br_taken_9, rob_br_taken_8, rob_br_taken_7, rob_br_taken_6, rob_br_taken_5, rob_br_taken_4, rob_br_taken_3, rob_br_taken_2, rob_br_taken_1, rob_br_taken_0};
	wire [1023:0] _GEN_13 = {rob_br_target_15, rob_br_target_14, rob_br_target_13, rob_br_target_12, rob_br_target_11, rob_br_target_10, rob_br_target_9, rob_br_target_8, rob_br_target_7, rob_br_target_6, rob_br_target_5, rob_br_target_4, rob_br_target_3, rob_br_target_2, rob_br_target_1, rob_br_target_0};
	wire [1023:0] _GEN_14 = {rob_br_pc_15, rob_br_pc_14, rob_br_pc_13, rob_br_pc_12, rob_br_pc_11, rob_br_pc_10, rob_br_pc_9, rob_br_pc_8, rob_br_pc_7, rob_br_pc_6, rob_br_pc_5, rob_br_pc_4, rob_br_pc_3, rob_br_pc_2, rob_br_pc_1, rob_br_pc_0};
	always @(posedge clock) begin : sv2v_autoblock_1
		reg incoming_ptr_phase;
		reg _GEN_15;
		reg _GEN_16;
		reg is_wb_0;
		reg is_wb_1;
		reg is_wb;
		reg _rob_br_pc_0_T;
		reg is_wb_0_1;
		reg is_wb_1_1;
		reg is_wb_2;
		reg _rob_br_pc_1_T;
		reg is_wb_0_2;
		reg is_wb_1_2;
		reg is_wb_3;
		reg _rob_br_pc_2_T;
		reg is_wb_0_3;
		reg is_wb_1_3;
		reg is_wb_4;
		reg _rob_br_pc_3_T;
		reg is_wb_0_4;
		reg is_wb_1_4;
		reg is_wb_5;
		reg _rob_br_pc_4_T;
		reg is_wb_0_5;
		reg is_wb_1_5;
		reg is_wb_6;
		reg _rob_br_pc_5_T;
		reg is_wb_0_6;
		reg is_wb_1_6;
		reg is_wb_7;
		reg _rob_br_pc_6_T;
		reg is_wb_0_7;
		reg is_wb_1_7;
		reg is_wb_8;
		reg _rob_br_pc_7_T;
		reg is_wb_0_8;
		reg is_wb_1_8;
		reg is_wb_9;
		reg _rob_br_pc_8_T;
		reg is_wb_0_9;
		reg is_wb_1_9;
		reg is_wb_10;
		reg _rob_br_pc_9_T;
		reg is_wb_0_10;
		reg is_wb_1_10;
		reg is_wb_11;
		reg _rob_br_pc_10_T;
		reg is_wb_0_11;
		reg is_wb_1_11;
		reg is_wb_12;
		reg _rob_br_pc_11_T;
		reg is_wb_0_12;
		reg is_wb_1_12;
		reg is_wb_13;
		reg _rob_br_pc_12_T;
		reg is_wb_0_13;
		reg is_wb_1_13;
		reg is_wb_14;
		reg _rob_br_pc_13_T;
		reg is_wb_0_14;
		reg is_wb_1_14;
		reg is_wb_15;
		reg _rob_br_pc_14_T;
		reg is_wb_0_15;
		reg is_wb_1_15;
		reg is_wb_16;
		reg _rob_br_pc_15_T;
		incoming_ptr_phase = head[4] ^ (io_br_res_bits_rob_idx < head[3:0]);
		_GEN_15 = (io_br_res_valid & io_br_res_bits_mispredicted) & (~state | (({incoming_ptr_phase, io_br_res_bits_rob_idx} - head) < (target_ptr - head)));
		_GEN_16 = walk_ptr == target_ptr;
		is_wb_0 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h0);
		is_wb_1 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h0);
		is_wb = is_wb_0 | is_wb_1;
		_rob_br_pc_0_T = (is_wb & is_wb_0) & io_cdb_0_bits_is_branch;
		is_wb_0_1 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h1);
		is_wb_1_1 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h1);
		is_wb_2 = is_wb_0_1 | is_wb_1_1;
		_rob_br_pc_1_T = (is_wb_2 & is_wb_0_1) & io_cdb_0_bits_is_branch;
		is_wb_0_2 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h2);
		is_wb_1_2 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h2);
		is_wb_3 = is_wb_0_2 | is_wb_1_2;
		_rob_br_pc_2_T = (is_wb_3 & is_wb_0_2) & io_cdb_0_bits_is_branch;
		is_wb_0_3 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h3);
		is_wb_1_3 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h3);
		is_wb_4 = is_wb_0_3 | is_wb_1_3;
		_rob_br_pc_3_T = (is_wb_4 & is_wb_0_3) & io_cdb_0_bits_is_branch;
		is_wb_0_4 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h4);
		is_wb_1_4 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h4);
		is_wb_5 = is_wb_0_4 | is_wb_1_4;
		_rob_br_pc_4_T = (is_wb_5 & is_wb_0_4) & io_cdb_0_bits_is_branch;
		is_wb_0_5 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h5);
		is_wb_1_5 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h5);
		is_wb_6 = is_wb_0_5 | is_wb_1_5;
		_rob_br_pc_5_T = (is_wb_6 & is_wb_0_5) & io_cdb_0_bits_is_branch;
		is_wb_0_6 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h6);
		is_wb_1_6 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h6);
		is_wb_7 = is_wb_0_6 | is_wb_1_6;
		_rob_br_pc_6_T = (is_wb_7 & is_wb_0_6) & io_cdb_0_bits_is_branch;
		is_wb_0_7 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h7);
		is_wb_1_7 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h7);
		is_wb_8 = is_wb_0_7 | is_wb_1_7;
		_rob_br_pc_7_T = (is_wb_8 & is_wb_0_7) & io_cdb_0_bits_is_branch;
		is_wb_0_8 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h8);
		is_wb_1_8 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h8);
		is_wb_9 = is_wb_0_8 | is_wb_1_8;
		_rob_br_pc_8_T = (is_wb_9 & is_wb_0_8) & io_cdb_0_bits_is_branch;
		is_wb_0_9 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'h9);
		is_wb_1_9 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'h9);
		is_wb_10 = is_wb_0_9 | is_wb_1_9;
		_rob_br_pc_9_T = (is_wb_10 & is_wb_0_9) & io_cdb_0_bits_is_branch;
		is_wb_0_10 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'ha);
		is_wb_1_10 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'ha);
		is_wb_11 = is_wb_0_10 | is_wb_1_10;
		_rob_br_pc_10_T = (is_wb_11 & is_wb_0_10) & io_cdb_0_bits_is_branch;
		is_wb_0_11 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'hb);
		is_wb_1_11 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'hb);
		is_wb_12 = is_wb_0_11 | is_wb_1_11;
		_rob_br_pc_11_T = (is_wb_12 & is_wb_0_11) & io_cdb_0_bits_is_branch;
		is_wb_0_12 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'hc);
		is_wb_1_12 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'hc);
		is_wb_13 = is_wb_0_12 | is_wb_1_12;
		_rob_br_pc_12_T = (is_wb_13 & is_wb_0_12) & io_cdb_0_bits_is_branch;
		is_wb_0_13 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'hd);
		is_wb_1_13 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'hd);
		is_wb_14 = is_wb_0_13 | is_wb_1_13;
		_rob_br_pc_13_T = (is_wb_14 & is_wb_0_13) & io_cdb_0_bits_is_branch;
		is_wb_0_14 = io_cdb_0_valid & (io_cdb_0_bits_rob_idx == 4'he);
		is_wb_1_14 = io_cdb_1_valid & (io_cdb_1_bits_rob_idx == 4'he);
		is_wb_15 = is_wb_0_14 | is_wb_1_14;
		_rob_br_pc_14_T = (is_wb_15 & is_wb_0_14) & io_cdb_0_bits_is_branch;
		is_wb_0_15 = io_cdb_0_valid & (&io_cdb_0_bits_rob_idx);
		is_wb_1_15 = io_cdb_1_valid & (&io_cdb_1_bits_rob_idx);
		is_wb_16 = is_wb_0_15 | is_wb_1_15;
		_rob_br_pc_15_T = (is_wb_16 & is_wb_0_15) & io_cdb_0_bits_is_branch;
		if (reset) begin
			rob_busy_0 <= 1'h0;
			rob_busy_1 <= 1'h0;
			rob_busy_2 <= 1'h0;
			rob_busy_3 <= 1'h0;
			rob_busy_4 <= 1'h0;
			rob_busy_5 <= 1'h0;
			rob_busy_6 <= 1'h0;
			rob_busy_7 <= 1'h0;
			rob_busy_8 <= 1'h0;
			rob_busy_9 <= 1'h0;
			rob_busy_10 <= 1'h0;
			rob_busy_11 <= 1'h0;
			rob_busy_12 <= 1'h0;
			rob_busy_13 <= 1'h0;
			rob_busy_14 <= 1'h0;
			rob_busy_15 <= 1'h0;
			rob_complete_0 <= 1'h0;
			rob_complete_1 <= 1'h0;
			rob_complete_2 <= 1'h0;
			rob_complete_3 <= 1'h0;
			rob_complete_4 <= 1'h0;
			rob_complete_5 <= 1'h0;
			rob_complete_6 <= 1'h0;
			rob_complete_7 <= 1'h0;
			rob_complete_8 <= 1'h0;
			rob_complete_9 <= 1'h0;
			rob_complete_10 <= 1'h0;
			rob_complete_11 <= 1'h0;
			rob_complete_12 <= 1'h0;
			rob_complete_13 <= 1'h0;
			rob_complete_14 <= 1'h0;
			rob_complete_15 <= 1'h0;
			rob_exc_0 <= 1'h0;
			rob_exc_1 <= 1'h0;
			rob_exc_2 <= 1'h0;
			rob_exc_3 <= 1'h0;
			rob_exc_4 <= 1'h0;
			rob_exc_5 <= 1'h0;
			rob_exc_6 <= 1'h0;
			rob_exc_7 <= 1'h0;
			rob_exc_8 <= 1'h0;
			rob_exc_9 <= 1'h0;
			rob_exc_10 <= 1'h0;
			rob_exc_11 <= 1'h0;
			rob_exc_12 <= 1'h0;
			rob_exc_13 <= 1'h0;
			rob_exc_14 <= 1'h0;
			rob_exc_15 <= 1'h0;
			rob_rf_wen_0 <= 1'h0;
			rob_rf_wen_1 <= 1'h0;
			rob_rf_wen_2 <= 1'h0;
			rob_rf_wen_3 <= 1'h0;
			rob_rf_wen_4 <= 1'h0;
			rob_rf_wen_5 <= 1'h0;
			rob_rf_wen_6 <= 1'h0;
			rob_rf_wen_7 <= 1'h0;
			rob_rf_wen_8 <= 1'h0;
			rob_rf_wen_9 <= 1'h0;
			rob_rf_wen_10 <= 1'h0;
			rob_rf_wen_11 <= 1'h0;
			rob_rf_wen_12 <= 1'h0;
			rob_rf_wen_13 <= 1'h0;
			rob_rf_wen_14 <= 1'h0;
			rob_rf_wen_15 <= 1'h0;
			rob_is_store_0 <= 1'h0;
			rob_is_store_1 <= 1'h0;
			rob_is_store_2 <= 1'h0;
			rob_is_store_3 <= 1'h0;
			rob_is_store_4 <= 1'h0;
			rob_is_store_5 <= 1'h0;
			rob_is_store_6 <= 1'h0;
			rob_is_store_7 <= 1'h0;
			rob_is_store_8 <= 1'h0;
			rob_is_store_9 <= 1'h0;
			rob_is_store_10 <= 1'h0;
			rob_is_store_11 <= 1'h0;
			rob_is_store_12 <= 1'h0;
			rob_is_store_13 <= 1'h0;
			rob_is_store_14 <= 1'h0;
			rob_is_store_15 <= 1'h0;
			rob_stale_p_rd_0 <= 6'h00;
			rob_stale_p_rd_1 <= 6'h00;
			rob_stale_p_rd_2 <= 6'h00;
			rob_stale_p_rd_3 <= 6'h00;
			rob_stale_p_rd_4 <= 6'h00;
			rob_stale_p_rd_5 <= 6'h00;
			rob_stale_p_rd_6 <= 6'h00;
			rob_stale_p_rd_7 <= 6'h00;
			rob_stale_p_rd_8 <= 6'h00;
			rob_stale_p_rd_9 <= 6'h00;
			rob_stale_p_rd_10 <= 6'h00;
			rob_stale_p_rd_11 <= 6'h00;
			rob_stale_p_rd_12 <= 6'h00;
			rob_stale_p_rd_13 <= 6'h00;
			rob_stale_p_rd_14 <= 6'h00;
			rob_stale_p_rd_15 <= 6'h00;
			rob_l_rd_0 <= 5'h00;
			rob_l_rd_1 <= 5'h00;
			rob_l_rd_2 <= 5'h00;
			rob_l_rd_3 <= 5'h00;
			rob_l_rd_4 <= 5'h00;
			rob_l_rd_5 <= 5'h00;
			rob_l_rd_6 <= 5'h00;
			rob_l_rd_7 <= 5'h00;
			rob_l_rd_8 <= 5'h00;
			rob_l_rd_9 <= 5'h00;
			rob_l_rd_10 <= 5'h00;
			rob_l_rd_11 <= 5'h00;
			rob_l_rd_12 <= 5'h00;
			rob_l_rd_13 <= 5'h00;
			rob_l_rd_14 <= 5'h00;
			rob_l_rd_15 <= 5'h00;
			rob_p_rd_0 <= 6'h00;
			rob_p_rd_1 <= 6'h00;
			rob_p_rd_2 <= 6'h00;
			rob_p_rd_3 <= 6'h00;
			rob_p_rd_4 <= 6'h00;
			rob_p_rd_5 <= 6'h00;
			rob_p_rd_6 <= 6'h00;
			rob_p_rd_7 <= 6'h00;
			rob_p_rd_8 <= 6'h00;
			rob_p_rd_9 <= 6'h00;
			rob_p_rd_10 <= 6'h00;
			rob_p_rd_11 <= 6'h00;
			rob_p_rd_12 <= 6'h00;
			rob_p_rd_13 <= 6'h00;
			rob_p_rd_14 <= 6'h00;
			rob_p_rd_15 <= 6'h00;
			head <= 5'h00;
			tail <= 5'h00;
			rob_is_branch_0 <= 1'h0;
			rob_is_branch_1 <= 1'h0;
			rob_is_branch_2 <= 1'h0;
			rob_is_branch_3 <= 1'h0;
			rob_is_branch_4 <= 1'h0;
			rob_is_branch_5 <= 1'h0;
			rob_is_branch_6 <= 1'h0;
			rob_is_branch_7 <= 1'h0;
			rob_is_branch_8 <= 1'h0;
			rob_is_branch_9 <= 1'h0;
			rob_is_branch_10 <= 1'h0;
			rob_is_branch_11 <= 1'h0;
			rob_is_branch_12 <= 1'h0;
			rob_is_branch_13 <= 1'h0;
			rob_is_branch_14 <= 1'h0;
			rob_is_branch_15 <= 1'h0;
			state <= 1'h0;
			debug_rob_inst_0 <= 32'h00000000;
			debug_rob_inst_1 <= 32'h00000000;
			debug_rob_inst_2 <= 32'h00000000;
			debug_rob_inst_3 <= 32'h00000000;
			debug_rob_inst_4 <= 32'h00000000;
			debug_rob_inst_5 <= 32'h00000000;
			debug_rob_inst_6 <= 32'h00000000;
			debug_rob_inst_7 <= 32'h00000000;
			debug_rob_inst_8 <= 32'h00000000;
			debug_rob_inst_9 <= 32'h00000000;
			debug_rob_inst_10 <= 32'h00000000;
			debug_rob_inst_11 <= 32'h00000000;
			debug_rob_inst_12 <= 32'h00000000;
			debug_rob_inst_13 <= 32'h00000000;
			debug_rob_inst_14 <= 32'h00000000;
			debug_rob_inst_15 <= 32'h00000000;
		end
		else begin : sv2v_autoblock_2
			reg _GEN_17;
			reg do_alloc;
			reg is_alloced_0;
			reg is_alloc;
			reg is_alloced_0_1;
			reg is_alloc_1;
			reg is_alloced_0_2;
			reg is_alloc_2;
			reg is_alloced_0_3;
			reg is_alloc_3;
			reg is_alloced_0_4;
			reg is_alloc_4;
			reg is_alloced_0_5;
			reg is_alloc_5;
			reg is_alloced_0_6;
			reg is_alloc_6;
			reg is_alloced_0_7;
			reg is_alloc_7;
			reg is_alloced_0_8;
			reg is_alloc_8;
			reg is_alloced_0_9;
			reg is_alloc_9;
			reg is_alloced_0_10;
			reg is_alloc_10;
			reg is_alloced_0_11;
			reg is_alloc_11;
			reg is_alloced_0_12;
			reg is_alloc_12;
			reg is_alloced_0_13;
			reg is_alloc_13;
			reg is_alloced_0_14;
			reg is_alloc_14;
			reg is_alloced_0_15;
			reg is_alloc_15;
			_GEN_17 = state & _GEN_16;
			do_alloc = io_enq_valid & io_enq_ready_0;
			is_alloced_0 = do_alloc & (tail[3:0] == 4'h0);
			is_alloc = is_alloced_0 | (do_alloc & (_tail_1_sum_T == 4'h0));
			is_alloced_0_1 = do_alloc & (tail[3:0] == 4'h1);
			is_alloc_1 = is_alloced_0_1 | (do_alloc & (_tail_1_sum_T == 4'h1));
			is_alloced_0_2 = do_alloc & (tail[3:0] == 4'h2);
			is_alloc_2 = is_alloced_0_2 | (do_alloc & (_tail_1_sum_T == 4'h2));
			is_alloced_0_3 = do_alloc & (tail[3:0] == 4'h3);
			is_alloc_3 = is_alloced_0_3 | (do_alloc & (_tail_1_sum_T == 4'h3));
			is_alloced_0_4 = do_alloc & (tail[3:0] == 4'h4);
			is_alloc_4 = is_alloced_0_4 | (do_alloc & (_tail_1_sum_T == 4'h4));
			is_alloced_0_5 = do_alloc & (tail[3:0] == 4'h5);
			is_alloc_5 = is_alloced_0_5 | (do_alloc & (_tail_1_sum_T == 4'h5));
			is_alloced_0_6 = do_alloc & (tail[3:0] == 4'h6);
			is_alloc_6 = is_alloced_0_6 | (do_alloc & (_tail_1_sum_T == 4'h6));
			is_alloced_0_7 = do_alloc & (tail[3:0] == 4'h7);
			is_alloc_7 = is_alloced_0_7 | (do_alloc & (_tail_1_sum_T == 4'h7));
			is_alloced_0_8 = do_alloc & (tail[3:0] == 4'h8);
			is_alloc_8 = is_alloced_0_8 | (do_alloc & (_tail_1_sum_T == 4'h8));
			is_alloced_0_9 = do_alloc & (tail[3:0] == 4'h9);
			is_alloc_9 = is_alloced_0_9 | (do_alloc & (_tail_1_sum_T == 4'h9));
			is_alloced_0_10 = do_alloc & (tail[3:0] == 4'ha);
			is_alloc_10 = is_alloced_0_10 | (do_alloc & (_tail_1_sum_T == 4'ha));
			is_alloced_0_11 = do_alloc & (tail[3:0] == 4'hb);
			is_alloc_11 = is_alloced_0_11 | (do_alloc & (_tail_1_sum_T == 4'hb));
			is_alloced_0_12 = do_alloc & (tail[3:0] == 4'hc);
			is_alloc_12 = is_alloced_0_12 | (do_alloc & (_tail_1_sum_T == 4'hc));
			is_alloced_0_13 = do_alloc & (tail[3:0] == 4'hd);
			is_alloc_13 = is_alloced_0_13 | (do_alloc & (_tail_1_sum_T == 4'hd));
			is_alloced_0_14 = do_alloc & (tail[3:0] == 4'he);
			is_alloc_14 = is_alloced_0_14 | (do_alloc & (_tail_1_sum_T == 4'he));
			is_alloced_0_15 = do_alloc & (&tail[3:0]);
			is_alloc_15 = is_alloced_0_15 | (do_alloc & (&_tail_1_sum_T));
			rob_busy_0 <= is_alloc | (~(((|commit_count & (head[3:0] == 4'h0)) | (cmt1_fire & (_head_1_sum_T == 4'h0))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h0))) & rob_busy_0);
			rob_busy_1 <= is_alloc_1 | (~(((|commit_count & (head[3:0] == 4'h1)) | (cmt1_fire & (_head_1_sum_T == 4'h1))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h1))) & rob_busy_1);
			rob_busy_2 <= is_alloc_2 | (~(((|commit_count & (head[3:0] == 4'h2)) | (cmt1_fire & (_head_1_sum_T == 4'h2))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h2))) & rob_busy_2);
			rob_busy_3 <= is_alloc_3 | (~(((|commit_count & (head[3:0] == 4'h3)) | (cmt1_fire & (_head_1_sum_T == 4'h3))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h3))) & rob_busy_3);
			rob_busy_4 <= is_alloc_4 | (~(((|commit_count & (head[3:0] == 4'h4)) | (cmt1_fire & (_head_1_sum_T == 4'h4))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h4))) & rob_busy_4);
			rob_busy_5 <= is_alloc_5 | (~(((|commit_count & (head[3:0] == 4'h5)) | (cmt1_fire & (_head_1_sum_T == 4'h5))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h5))) & rob_busy_5);
			rob_busy_6 <= is_alloc_6 | (~(((|commit_count & (head[3:0] == 4'h6)) | (cmt1_fire & (_head_1_sum_T == 4'h6))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h6))) & rob_busy_6);
			rob_busy_7 <= is_alloc_7 | (~(((|commit_count & (head[3:0] == 4'h7)) | (cmt1_fire & (_head_1_sum_T == 4'h7))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h7))) & rob_busy_7);
			rob_busy_8 <= is_alloc_8 | (~(((|commit_count & (head[3:0] == 4'h8)) | (cmt1_fire & (_head_1_sum_T == 4'h8))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h8))) & rob_busy_8);
			rob_busy_9 <= is_alloc_9 | (~(((|commit_count & (head[3:0] == 4'h9)) | (cmt1_fire & (_head_1_sum_T == 4'h9))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'h9))) & rob_busy_9);
			rob_busy_10 <= is_alloc_10 | (~(((|commit_count & (head[3:0] == 4'ha)) | (cmt1_fire & (_head_1_sum_T == 4'ha))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'ha))) & rob_busy_10);
			rob_busy_11 <= is_alloc_11 | (~(((|commit_count & (head[3:0] == 4'hb)) | (cmt1_fire & (_head_1_sum_T == 4'hb))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'hb))) & rob_busy_11);
			rob_busy_12 <= is_alloc_12 | (~(((|commit_count & (head[3:0] == 4'hc)) | (cmt1_fire & (_head_1_sum_T == 4'hc))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'hc))) & rob_busy_12);
			rob_busy_13 <= is_alloc_13 | (~(((|commit_count & (head[3:0] == 4'hd)) | (cmt1_fire & (_head_1_sum_T == 4'hd))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'hd))) & rob_busy_13);
			rob_busy_14 <= is_alloc_14 | (~(((|commit_count & (head[3:0] == 4'he)) | (cmt1_fire & (_head_1_sum_T == 4'he))) | ((state & _is_rbk_clear_T_45) & (walk_ptr[3:0] == 4'he))) & rob_busy_14);
			rob_busy_15 <= is_alloc_15 | (~(((|commit_count & (&head[3:0])) | (cmt1_fire & (&_head_1_sum_T))) | ((state & _is_rbk_clear_T_45) & (&walk_ptr[3:0]))) & rob_busy_15);
			if (is_alloc) begin : sv2v_autoblock_3
				reg alloc_uop_valid;
				alloc_uop_valid = (is_alloced_0 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_0 <= ~alloc_uop_valid;
				if (is_alloced_0)
					rob_exc_0 <= io_enq_bits_0_exception;
				else
					rob_exc_0 <= io_enq_bits_1_exception;
				rob_rf_wen_0 <= (is_alloced_0 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_valid;
				rob_is_store_0 <= ((is_alloced_0 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_valid;
				rob_stale_p_rd_0 <= (is_alloced_0 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_0 <= (is_alloced_0 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_0 <= (is_alloced_0 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_0 <= (is_alloced_0 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_0 <= is_wb | rob_complete_0;
				rob_exc_0 <= (is_wb & ((is_wb_0 & io_cdb_0_bits_exc) | (is_wb_1 & io_cdb_1_bits_exc))) | rob_exc_0;
			end
			if (is_alloc_1) begin : sv2v_autoblock_4
				reg alloc_uop_1_valid;
				alloc_uop_1_valid = (is_alloced_0_1 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_1 <= ~alloc_uop_1_valid;
				if (is_alloced_0_1)
					rob_exc_1 <= io_enq_bits_0_exception;
				else
					rob_exc_1 <= io_enq_bits_1_exception;
				rob_rf_wen_1 <= (is_alloced_0_1 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_1_valid;
				rob_is_store_1 <= ((is_alloced_0_1 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_1_valid;
				rob_stale_p_rd_1 <= (is_alloced_0_1 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_1 <= (is_alloced_0_1 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_1 <= (is_alloced_0_1 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_1 <= (is_alloced_0_1 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_1 <= is_wb_2 | rob_complete_1;
				rob_exc_1 <= (is_wb_2 & ((is_wb_0_1 & io_cdb_0_bits_exc) | (is_wb_1_1 & io_cdb_1_bits_exc))) | rob_exc_1;
			end
			if (is_alloc_2) begin : sv2v_autoblock_5
				reg alloc_uop_2_valid;
				alloc_uop_2_valid = (is_alloced_0_2 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_2 <= ~alloc_uop_2_valid;
				if (is_alloced_0_2)
					rob_exc_2 <= io_enq_bits_0_exception;
				else
					rob_exc_2 <= io_enq_bits_1_exception;
				rob_rf_wen_2 <= (is_alloced_0_2 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_2_valid;
				rob_is_store_2 <= ((is_alloced_0_2 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_2_valid;
				rob_stale_p_rd_2 <= (is_alloced_0_2 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_2 <= (is_alloced_0_2 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_2 <= (is_alloced_0_2 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_2 <= (is_alloced_0_2 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_2 <= is_wb_3 | rob_complete_2;
				rob_exc_2 <= (is_wb_3 & ((is_wb_0_2 & io_cdb_0_bits_exc) | (is_wb_1_2 & io_cdb_1_bits_exc))) | rob_exc_2;
			end
			if (is_alloc_3) begin : sv2v_autoblock_6
				reg alloc_uop_3_valid;
				alloc_uop_3_valid = (is_alloced_0_3 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_3 <= ~alloc_uop_3_valid;
				if (is_alloced_0_3)
					rob_exc_3 <= io_enq_bits_0_exception;
				else
					rob_exc_3 <= io_enq_bits_1_exception;
				rob_rf_wen_3 <= (is_alloced_0_3 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_3_valid;
				rob_is_store_3 <= ((is_alloced_0_3 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_3_valid;
				rob_stale_p_rd_3 <= (is_alloced_0_3 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_3 <= (is_alloced_0_3 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_3 <= (is_alloced_0_3 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_3 <= (is_alloced_0_3 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_3 <= is_wb_4 | rob_complete_3;
				rob_exc_3 <= (is_wb_4 & ((is_wb_0_3 & io_cdb_0_bits_exc) | (is_wb_1_3 & io_cdb_1_bits_exc))) | rob_exc_3;
			end
			if (is_alloc_4) begin : sv2v_autoblock_7
				reg alloc_uop_4_valid;
				alloc_uop_4_valid = (is_alloced_0_4 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_4 <= ~alloc_uop_4_valid;
				if (is_alloced_0_4)
					rob_exc_4 <= io_enq_bits_0_exception;
				else
					rob_exc_4 <= io_enq_bits_1_exception;
				rob_rf_wen_4 <= (is_alloced_0_4 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_4_valid;
				rob_is_store_4 <= ((is_alloced_0_4 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_4_valid;
				rob_stale_p_rd_4 <= (is_alloced_0_4 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_4 <= (is_alloced_0_4 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_4 <= (is_alloced_0_4 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_4 <= (is_alloced_0_4 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_4 <= is_wb_5 | rob_complete_4;
				rob_exc_4 <= (is_wb_5 & ((is_wb_0_4 & io_cdb_0_bits_exc) | (is_wb_1_4 & io_cdb_1_bits_exc))) | rob_exc_4;
			end
			if (is_alloc_5) begin : sv2v_autoblock_8
				reg alloc_uop_5_valid;
				alloc_uop_5_valid = (is_alloced_0_5 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_5 <= ~alloc_uop_5_valid;
				if (is_alloced_0_5)
					rob_exc_5 <= io_enq_bits_0_exception;
				else
					rob_exc_5 <= io_enq_bits_1_exception;
				rob_rf_wen_5 <= (is_alloced_0_5 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_5_valid;
				rob_is_store_5 <= ((is_alloced_0_5 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_5_valid;
				rob_stale_p_rd_5 <= (is_alloced_0_5 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_5 <= (is_alloced_0_5 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_5 <= (is_alloced_0_5 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_5 <= (is_alloced_0_5 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_5 <= is_wb_6 | rob_complete_5;
				rob_exc_5 <= (is_wb_6 & ((is_wb_0_5 & io_cdb_0_bits_exc) | (is_wb_1_5 & io_cdb_1_bits_exc))) | rob_exc_5;
			end
			if (is_alloc_6) begin : sv2v_autoblock_9
				reg alloc_uop_6_valid;
				alloc_uop_6_valid = (is_alloced_0_6 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_6 <= ~alloc_uop_6_valid;
				if (is_alloced_0_6)
					rob_exc_6 <= io_enq_bits_0_exception;
				else
					rob_exc_6 <= io_enq_bits_1_exception;
				rob_rf_wen_6 <= (is_alloced_0_6 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_6_valid;
				rob_is_store_6 <= ((is_alloced_0_6 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_6_valid;
				rob_stale_p_rd_6 <= (is_alloced_0_6 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_6 <= (is_alloced_0_6 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_6 <= (is_alloced_0_6 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_6 <= (is_alloced_0_6 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_6 <= is_wb_7 | rob_complete_6;
				rob_exc_6 <= (is_wb_7 & ((is_wb_0_6 & io_cdb_0_bits_exc) | (is_wb_1_6 & io_cdb_1_bits_exc))) | rob_exc_6;
			end
			if (is_alloc_7) begin : sv2v_autoblock_10
				reg alloc_uop_7_valid;
				alloc_uop_7_valid = (is_alloced_0_7 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_7 <= ~alloc_uop_7_valid;
				if (is_alloced_0_7)
					rob_exc_7 <= io_enq_bits_0_exception;
				else
					rob_exc_7 <= io_enq_bits_1_exception;
				rob_rf_wen_7 <= (is_alloced_0_7 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_7_valid;
				rob_is_store_7 <= ((is_alloced_0_7 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_7_valid;
				rob_stale_p_rd_7 <= (is_alloced_0_7 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_7 <= (is_alloced_0_7 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_7 <= (is_alloced_0_7 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_7 <= (is_alloced_0_7 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_7 <= is_wb_8 | rob_complete_7;
				rob_exc_7 <= (is_wb_8 & ((is_wb_0_7 & io_cdb_0_bits_exc) | (is_wb_1_7 & io_cdb_1_bits_exc))) | rob_exc_7;
			end
			if (is_alloc_8) begin : sv2v_autoblock_11
				reg alloc_uop_8_valid;
				alloc_uop_8_valid = (is_alloced_0_8 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_8 <= ~alloc_uop_8_valid;
				if (is_alloced_0_8)
					rob_exc_8 <= io_enq_bits_0_exception;
				else
					rob_exc_8 <= io_enq_bits_1_exception;
				rob_rf_wen_8 <= (is_alloced_0_8 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_8_valid;
				rob_is_store_8 <= ((is_alloced_0_8 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_8_valid;
				rob_stale_p_rd_8 <= (is_alloced_0_8 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_8 <= (is_alloced_0_8 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_8 <= (is_alloced_0_8 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_8 <= (is_alloced_0_8 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_8 <= is_wb_9 | rob_complete_8;
				rob_exc_8 <= (is_wb_9 & ((is_wb_0_8 & io_cdb_0_bits_exc) | (is_wb_1_8 & io_cdb_1_bits_exc))) | rob_exc_8;
			end
			if (is_alloc_9) begin : sv2v_autoblock_12
				reg alloc_uop_9_valid;
				alloc_uop_9_valid = (is_alloced_0_9 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_9 <= ~alloc_uop_9_valid;
				if (is_alloced_0_9)
					rob_exc_9 <= io_enq_bits_0_exception;
				else
					rob_exc_9 <= io_enq_bits_1_exception;
				rob_rf_wen_9 <= (is_alloced_0_9 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_9_valid;
				rob_is_store_9 <= ((is_alloced_0_9 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_9_valid;
				rob_stale_p_rd_9 <= (is_alloced_0_9 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_9 <= (is_alloced_0_9 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_9 <= (is_alloced_0_9 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_9 <= (is_alloced_0_9 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_9 <= is_wb_10 | rob_complete_9;
				rob_exc_9 <= (is_wb_10 & ((is_wb_0_9 & io_cdb_0_bits_exc) | (is_wb_1_9 & io_cdb_1_bits_exc))) | rob_exc_9;
			end
			if (is_alloc_10) begin : sv2v_autoblock_13
				reg alloc_uop_10_valid;
				alloc_uop_10_valid = (is_alloced_0_10 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_10 <= ~alloc_uop_10_valid;
				if (is_alloced_0_10)
					rob_exc_10 <= io_enq_bits_0_exception;
				else
					rob_exc_10 <= io_enq_bits_1_exception;
				rob_rf_wen_10 <= (is_alloced_0_10 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_10_valid;
				rob_is_store_10 <= ((is_alloced_0_10 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_10_valid;
				rob_stale_p_rd_10 <= (is_alloced_0_10 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_10 <= (is_alloced_0_10 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_10 <= (is_alloced_0_10 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_10 <= (is_alloced_0_10 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_10 <= is_wb_11 | rob_complete_10;
				rob_exc_10 <= (is_wb_11 & ((is_wb_0_10 & io_cdb_0_bits_exc) | (is_wb_1_10 & io_cdb_1_bits_exc))) | rob_exc_10;
			end
			if (is_alloc_11) begin : sv2v_autoblock_14
				reg alloc_uop_11_valid;
				alloc_uop_11_valid = (is_alloced_0_11 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_11 <= ~alloc_uop_11_valid;
				if (is_alloced_0_11)
					rob_exc_11 <= io_enq_bits_0_exception;
				else
					rob_exc_11 <= io_enq_bits_1_exception;
				rob_rf_wen_11 <= (is_alloced_0_11 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_11_valid;
				rob_is_store_11 <= ((is_alloced_0_11 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_11_valid;
				rob_stale_p_rd_11 <= (is_alloced_0_11 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_11 <= (is_alloced_0_11 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_11 <= (is_alloced_0_11 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_11 <= (is_alloced_0_11 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_11 <= is_wb_12 | rob_complete_11;
				rob_exc_11 <= (is_wb_12 & ((is_wb_0_11 & io_cdb_0_bits_exc) | (is_wb_1_11 & io_cdb_1_bits_exc))) | rob_exc_11;
			end
			if (is_alloc_12) begin : sv2v_autoblock_15
				reg alloc_uop_12_valid;
				alloc_uop_12_valid = (is_alloced_0_12 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_12 <= ~alloc_uop_12_valid;
				if (is_alloced_0_12)
					rob_exc_12 <= io_enq_bits_0_exception;
				else
					rob_exc_12 <= io_enq_bits_1_exception;
				rob_rf_wen_12 <= (is_alloced_0_12 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_12_valid;
				rob_is_store_12 <= ((is_alloced_0_12 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_12_valid;
				rob_stale_p_rd_12 <= (is_alloced_0_12 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_12 <= (is_alloced_0_12 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_12 <= (is_alloced_0_12 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_12 <= (is_alloced_0_12 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_12 <= is_wb_13 | rob_complete_12;
				rob_exc_12 <= (is_wb_13 & ((is_wb_0_12 & io_cdb_0_bits_exc) | (is_wb_1_12 & io_cdb_1_bits_exc))) | rob_exc_12;
			end
			if (is_alloc_13) begin : sv2v_autoblock_16
				reg alloc_uop_13_valid;
				alloc_uop_13_valid = (is_alloced_0_13 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_13 <= ~alloc_uop_13_valid;
				if (is_alloced_0_13)
					rob_exc_13 <= io_enq_bits_0_exception;
				else
					rob_exc_13 <= io_enq_bits_1_exception;
				rob_rf_wen_13 <= (is_alloced_0_13 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_13_valid;
				rob_is_store_13 <= ((is_alloced_0_13 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_13_valid;
				rob_stale_p_rd_13 <= (is_alloced_0_13 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_13 <= (is_alloced_0_13 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_13 <= (is_alloced_0_13 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_13 <= (is_alloced_0_13 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_13 <= is_wb_14 | rob_complete_13;
				rob_exc_13 <= (is_wb_14 & ((is_wb_0_13 & io_cdb_0_bits_exc) | (is_wb_1_13 & io_cdb_1_bits_exc))) | rob_exc_13;
			end
			if (is_alloc_14) begin : sv2v_autoblock_17
				reg alloc_uop_14_valid;
				alloc_uop_14_valid = (is_alloced_0_14 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_14 <= ~alloc_uop_14_valid;
				if (is_alloced_0_14)
					rob_exc_14 <= io_enq_bits_0_exception;
				else
					rob_exc_14 <= io_enq_bits_1_exception;
				rob_rf_wen_14 <= (is_alloced_0_14 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_14_valid;
				rob_is_store_14 <= ((is_alloced_0_14 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_14_valid;
				rob_stale_p_rd_14 <= (is_alloced_0_14 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_14 <= (is_alloced_0_14 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_14 <= (is_alloced_0_14 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_14 <= (is_alloced_0_14 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_14 <= is_wb_15 | rob_complete_14;
				rob_exc_14 <= (is_wb_15 & ((is_wb_0_14 & io_cdb_0_bits_exc) | (is_wb_1_14 & io_cdb_1_bits_exc))) | rob_exc_14;
			end
			if (is_alloc_15) begin : sv2v_autoblock_18
				reg alloc_uop_15_valid;
				alloc_uop_15_valid = (is_alloced_0_15 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
				rob_complete_15 <= ~alloc_uop_15_valid;
				if (is_alloced_0_15)
					rob_exc_15 <= io_enq_bits_0_exception;
				else
					rob_exc_15 <= io_enq_bits_1_exception;
				rob_rf_wen_15 <= (is_alloced_0_15 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen) & alloc_uop_15_valid;
				rob_is_store_15 <= ((is_alloced_0_15 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd) == 3'h2) & alloc_uop_15_valid;
				rob_stale_p_rd_15 <= (is_alloced_0_15 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
				rob_l_rd_15 <= (is_alloced_0_15 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
				rob_p_rd_15 <= (is_alloced_0_15 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
				debug_rob_inst_15 <= (is_alloced_0_15 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			end
			else begin
				rob_complete_15 <= is_wb_16 | rob_complete_15;
				rob_exc_15 <= (is_wb_16 & ((is_wb_0_15 & io_cdb_0_bits_exc) | (is_wb_1_15 & io_cdb_1_bits_exc))) | rob_exc_15;
			end
			head <= head + _GEN_9;
			if (state) begin
				if (_GEN_17)
					tail <= target_ptr + 5'h01;
			end
			else
				tail <= tail + {3'h0, do_alloc, 1'h0};
			rob_is_branch_0 <= ~is_alloc & (_rob_br_pc_0_T | rob_is_branch_0);
			rob_is_branch_1 <= ~is_alloc_1 & (_rob_br_pc_1_T | rob_is_branch_1);
			rob_is_branch_2 <= ~is_alloc_2 & (_rob_br_pc_2_T | rob_is_branch_2);
			rob_is_branch_3 <= ~is_alloc_3 & (_rob_br_pc_3_T | rob_is_branch_3);
			rob_is_branch_4 <= ~is_alloc_4 & (_rob_br_pc_4_T | rob_is_branch_4);
			rob_is_branch_5 <= ~is_alloc_5 & (_rob_br_pc_5_T | rob_is_branch_5);
			rob_is_branch_6 <= ~is_alloc_6 & (_rob_br_pc_6_T | rob_is_branch_6);
			rob_is_branch_7 <= ~is_alloc_7 & (_rob_br_pc_7_T | rob_is_branch_7);
			rob_is_branch_8 <= ~is_alloc_8 & (_rob_br_pc_8_T | rob_is_branch_8);
			rob_is_branch_9 <= ~is_alloc_9 & (_rob_br_pc_9_T | rob_is_branch_9);
			rob_is_branch_10 <= ~is_alloc_10 & (_rob_br_pc_10_T | rob_is_branch_10);
			rob_is_branch_11 <= ~is_alloc_11 & (_rob_br_pc_11_T | rob_is_branch_11);
			rob_is_branch_12 <= ~is_alloc_12 & (_rob_br_pc_12_T | rob_is_branch_12);
			rob_is_branch_13 <= ~is_alloc_13 & (_rob_br_pc_13_T | rob_is_branch_13);
			rob_is_branch_14 <= ~is_alloc_14 & (_rob_br_pc_14_T | rob_is_branch_14);
			rob_is_branch_15 <= ~is_alloc_15 & (_rob_br_pc_15_T | rob_is_branch_15);
			state <= ~_GEN_17 & (_GEN_15 | state);
		end
		if (_rob_br_pc_0_T) begin
			rob_br_taken_0 <= is_wb_0 & io_cdb_0_bits_br_taken;
			rob_br_target_0 <= (is_wb_0 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_0 <= (is_wb_0 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_1_T) begin
			rob_br_taken_1 <= is_wb_0_1 & io_cdb_0_bits_br_taken;
			rob_br_target_1 <= (is_wb_0_1 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_1 <= (is_wb_0_1 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_2_T) begin
			rob_br_taken_2 <= is_wb_0_2 & io_cdb_0_bits_br_taken;
			rob_br_target_2 <= (is_wb_0_2 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_2 <= (is_wb_0_2 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_3_T) begin
			rob_br_taken_3 <= is_wb_0_3 & io_cdb_0_bits_br_taken;
			rob_br_target_3 <= (is_wb_0_3 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_3 <= (is_wb_0_3 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_4_T) begin
			rob_br_taken_4 <= is_wb_0_4 & io_cdb_0_bits_br_taken;
			rob_br_target_4 <= (is_wb_0_4 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_4 <= (is_wb_0_4 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_5_T) begin
			rob_br_taken_5 <= is_wb_0_5 & io_cdb_0_bits_br_taken;
			rob_br_target_5 <= (is_wb_0_5 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_5 <= (is_wb_0_5 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_6_T) begin
			rob_br_taken_6 <= is_wb_0_6 & io_cdb_0_bits_br_taken;
			rob_br_target_6 <= (is_wb_0_6 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_6 <= (is_wb_0_6 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_7_T) begin
			rob_br_taken_7 <= is_wb_0_7 & io_cdb_0_bits_br_taken;
			rob_br_target_7 <= (is_wb_0_7 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_7 <= (is_wb_0_7 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_8_T) begin
			rob_br_taken_8 <= is_wb_0_8 & io_cdb_0_bits_br_taken;
			rob_br_target_8 <= (is_wb_0_8 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_8 <= (is_wb_0_8 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_9_T) begin
			rob_br_taken_9 <= is_wb_0_9 & io_cdb_0_bits_br_taken;
			rob_br_target_9 <= (is_wb_0_9 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_9 <= (is_wb_0_9 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_10_T) begin
			rob_br_taken_10 <= is_wb_0_10 & io_cdb_0_bits_br_taken;
			rob_br_target_10 <= (is_wb_0_10 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_10 <= (is_wb_0_10 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_11_T) begin
			rob_br_taken_11 <= is_wb_0_11 & io_cdb_0_bits_br_taken;
			rob_br_target_11 <= (is_wb_0_11 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_11 <= (is_wb_0_11 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_12_T) begin
			rob_br_taken_12 <= is_wb_0_12 & io_cdb_0_bits_br_taken;
			rob_br_target_12 <= (is_wb_0_12 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_12 <= (is_wb_0_12 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_13_T) begin
			rob_br_taken_13 <= is_wb_0_13 & io_cdb_0_bits_br_taken;
			rob_br_target_13 <= (is_wb_0_13 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_13 <= (is_wb_0_13 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_14_T) begin
			rob_br_taken_14 <= is_wb_0_14 & io_cdb_0_bits_br_taken;
			rob_br_target_14 <= (is_wb_0_14 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_14 <= (is_wb_0_14 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (_rob_br_pc_15_T) begin
			rob_br_taken_15 <= is_wb_0_15 & io_cdb_0_bits_br_taken;
			rob_br_target_15 <= (is_wb_0_15 ? io_cdb_0_bits_br_target : 64'h0000000000000000);
			rob_br_pc_15 <= (is_wb_0_15 ? io_cdb_0_bits_br_pc : 64'h0000000000000000);
		end
		if (~state | _GEN_16) begin
			if (_GEN_15)
				walk_ptr <= tail - 5'h01;
		end
		else
			walk_ptr <= walk_ptr - 5'h01;
		if (_GEN_15)
			target_ptr <= {incoming_ptr_phase, io_br_res_bits_rob_idx};
	end
	assign io_enq_ready = io_enq_ready_0;
	assign io_rob_idx_alloc_0 = tail[3:0];
	assign io_rob_idx_alloc_1 = _tail_1_sum_T;
	assign io_commit_free_0_valid = (|commit_count & _GEN[head[3:0]]) & |io_commit_free_0_bits_0;
	assign io_commit_free_0_bits = io_commit_free_0_bits_0;
	assign io_commit_free_1_valid = (cmt1_fire & _GEN[_head_1_sum_T]) & |_GEN_2[_head_1_sum_T * 6+:6];
	assign io_commit_free_1_bits = _GEN_2[_head_1_sum_T * 6+:6];
	assign io_flush_pipeline = ~state & (_GEN_7 | _GEN_8);
	assign io_commit_store_0_valid = |commit_count & _GEN_10[head[3:0]];
	assign io_commit_store_0_bits = head[3:0];
	assign io_commit_store_1_valid = cmt1_fire & _GEN_10[_head_1_sum_T];
	assign io_commit_store_1_bits = _head_1_sum_T;
	assign io_rbk_active = state;
	assign io_rbk_valid = (state & _GEN[walk_ptr[3:0]]) & _is_rbk_clear_T_45;
	assign io_rbk_l_rd = _GEN_0[walk_ptr[3:0] * 5+:5];
	assign io_rbk_p_rd = _GEN_1[walk_ptr[3:0] * 6+:6];
	assign io_rbk_stale_p_rd = _GEN_2[walk_ptr[3:0] * 6+:6];
	assign io_rob_head_idx = head[3:0];
	assign io_commit_num = commit_count;
	assign io_bpu_update_valid = |commit_count & _GEN_11[head[3:0]];
	assign io_bpu_update_bits_pc = _GEN_14[head[3:0] * 64+:64];
	assign io_bpu_update_bits_target = _GEN_13[head[3:0] * 64+:64];
	assign io_bpu_update_bits_taken = _GEN_12[head[3:0]];
endmodule
module IssueQueue (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_0_valid,
	io_enq_bits_0_pc,
	io_enq_bits_0_inst,
	io_enq_bits_0_fu_code,
	io_enq_bits_0_alu_op,
	io_enq_bits_0_op1_sel,
	io_enq_bits_0_op2_sel,
	io_enq_bits_0_imm,
	io_enq_bits_0_imm_sel,
	io_enq_bits_0_is_w,
	io_enq_bits_0_mem_cmd,
	io_enq_bits_0_mem_size,
	io_enq_bits_0_mem_signed,
	io_enq_bits_0_br_type,
	io_enq_bits_0_l_rd,
	io_enq_bits_0_l_rs1,
	io_enq_bits_0_l_rs2,
	io_enq_bits_0_rf_wen,
	io_enq_bits_0_use_rs1,
	io_enq_bits_0_use_rs2,
	io_enq_bits_0_p_rd,
	io_enq_bits_0_p_rs1,
	io_enq_bits_0_p_rs2,
	io_enq_bits_0_prs1_ready,
	io_enq_bits_0_prs2_ready,
	io_enq_bits_0_stale_p_rd,
	io_enq_bits_0_rob_idx,
	io_enq_bits_0_exception,
	io_enq_bits_0_pred_taken,
	io_enq_bits_0_pred_target,
	io_enq_bits_1_valid,
	io_enq_bits_1_pc,
	io_enq_bits_1_inst,
	io_enq_bits_1_fu_code,
	io_enq_bits_1_alu_op,
	io_enq_bits_1_op1_sel,
	io_enq_bits_1_op2_sel,
	io_enq_bits_1_imm,
	io_enq_bits_1_imm_sel,
	io_enq_bits_1_is_w,
	io_enq_bits_1_mem_cmd,
	io_enq_bits_1_mem_size,
	io_enq_bits_1_mem_signed,
	io_enq_bits_1_br_type,
	io_enq_bits_1_l_rd,
	io_enq_bits_1_l_rs1,
	io_enq_bits_1_l_rs2,
	io_enq_bits_1_rf_wen,
	io_enq_bits_1_use_rs1,
	io_enq_bits_1_use_rs2,
	io_enq_bits_1_p_rd,
	io_enq_bits_1_p_rs1,
	io_enq_bits_1_p_rs2,
	io_enq_bits_1_prs1_ready,
	io_enq_bits_1_prs2_ready,
	io_enq_bits_1_stale_p_rd,
	io_enq_bits_1_rob_idx,
	io_enq_bits_1_exception,
	io_enq_bits_1_pred_taken,
	io_enq_bits_1_pred_target,
	io_iss_alu_ready,
	io_iss_alu_valid,
	io_iss_alu_bits_valid,
	io_iss_alu_bits_pc,
	io_iss_alu_bits_inst,
	io_iss_alu_bits_fu_code,
	io_iss_alu_bits_alu_op,
	io_iss_alu_bits_op1_sel,
	io_iss_alu_bits_op2_sel,
	io_iss_alu_bits_imm,
	io_iss_alu_bits_imm_sel,
	io_iss_alu_bits_is_w,
	io_iss_alu_bits_mem_cmd,
	io_iss_alu_bits_mem_size,
	io_iss_alu_bits_mem_signed,
	io_iss_alu_bits_br_type,
	io_iss_alu_bits_l_rd,
	io_iss_alu_bits_l_rs1,
	io_iss_alu_bits_l_rs2,
	io_iss_alu_bits_rf_wen,
	io_iss_alu_bits_use_rs1,
	io_iss_alu_bits_use_rs2,
	io_iss_alu_bits_p_rd,
	io_iss_alu_bits_p_rs1,
	io_iss_alu_bits_p_rs2,
	io_iss_alu_bits_prs1_ready,
	io_iss_alu_bits_prs2_ready,
	io_iss_alu_bits_stale_p_rd,
	io_iss_alu_bits_rob_idx,
	io_iss_alu_bits_exception,
	io_iss_alu_bits_pred_taken,
	io_iss_alu_bits_pred_target,
	io_iss_lsu_ready,
	io_iss_lsu_valid,
	io_iss_lsu_bits_valid,
	io_iss_lsu_bits_pc,
	io_iss_lsu_bits_inst,
	io_iss_lsu_bits_fu_code,
	io_iss_lsu_bits_alu_op,
	io_iss_lsu_bits_op1_sel,
	io_iss_lsu_bits_op2_sel,
	io_iss_lsu_bits_imm,
	io_iss_lsu_bits_imm_sel,
	io_iss_lsu_bits_is_w,
	io_iss_lsu_bits_mem_cmd,
	io_iss_lsu_bits_mem_size,
	io_iss_lsu_bits_mem_signed,
	io_iss_lsu_bits_br_type,
	io_iss_lsu_bits_l_rd,
	io_iss_lsu_bits_l_rs1,
	io_iss_lsu_bits_l_rs2,
	io_iss_lsu_bits_rf_wen,
	io_iss_lsu_bits_use_rs1,
	io_iss_lsu_bits_use_rs2,
	io_iss_lsu_bits_p_rd,
	io_iss_lsu_bits_p_rs1,
	io_iss_lsu_bits_p_rs2,
	io_iss_lsu_bits_prs1_ready,
	io_iss_lsu_bits_prs2_ready,
	io_iss_lsu_bits_stale_p_rd,
	io_iss_lsu_bits_rob_idx,
	io_iss_lsu_bits_exception,
	io_iss_lsu_bits_pred_taken,
	io_iss_lsu_bits_pred_target,
	io_cdb_0_valid,
	io_cdb_0_bits_p_rd,
	io_cdb_1_valid,
	io_cdb_1_bits_p_rd,
	io_flush,
	io_flush_mispredict,
	io_mispredict_rob_idx,
	io_rob_head_idx
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_enq_bits_0_valid;
	input [63:0] io_enq_bits_0_pc;
	input [31:0] io_enq_bits_0_inst;
	input [5:0] io_enq_bits_0_fu_code;
	input [9:0] io_enq_bits_0_alu_op;
	input [1:0] io_enq_bits_0_op1_sel;
	input [2:0] io_enq_bits_0_op2_sel;
	input [63:0] io_enq_bits_0_imm;
	input [2:0] io_enq_bits_0_imm_sel;
	input io_enq_bits_0_is_w;
	input [2:0] io_enq_bits_0_mem_cmd;
	input [1:0] io_enq_bits_0_mem_size;
	input io_enq_bits_0_mem_signed;
	input [3:0] io_enq_bits_0_br_type;
	input [4:0] io_enq_bits_0_l_rd;
	input [4:0] io_enq_bits_0_l_rs1;
	input [4:0] io_enq_bits_0_l_rs2;
	input io_enq_bits_0_rf_wen;
	input io_enq_bits_0_use_rs1;
	input io_enq_bits_0_use_rs2;
	input [5:0] io_enq_bits_0_p_rd;
	input [5:0] io_enq_bits_0_p_rs1;
	input [5:0] io_enq_bits_0_p_rs2;
	input io_enq_bits_0_prs1_ready;
	input io_enq_bits_0_prs2_ready;
	input [5:0] io_enq_bits_0_stale_p_rd;
	input [3:0] io_enq_bits_0_rob_idx;
	input io_enq_bits_0_exception;
	input io_enq_bits_0_pred_taken;
	input [63:0] io_enq_bits_0_pred_target;
	input io_enq_bits_1_valid;
	input [63:0] io_enq_bits_1_pc;
	input [31:0] io_enq_bits_1_inst;
	input [5:0] io_enq_bits_1_fu_code;
	input [9:0] io_enq_bits_1_alu_op;
	input [1:0] io_enq_bits_1_op1_sel;
	input [2:0] io_enq_bits_1_op2_sel;
	input [63:0] io_enq_bits_1_imm;
	input [2:0] io_enq_bits_1_imm_sel;
	input io_enq_bits_1_is_w;
	input [2:0] io_enq_bits_1_mem_cmd;
	input [1:0] io_enq_bits_1_mem_size;
	input io_enq_bits_1_mem_signed;
	input [3:0] io_enq_bits_1_br_type;
	input [4:0] io_enq_bits_1_l_rd;
	input [4:0] io_enq_bits_1_l_rs1;
	input [4:0] io_enq_bits_1_l_rs2;
	input io_enq_bits_1_rf_wen;
	input io_enq_bits_1_use_rs1;
	input io_enq_bits_1_use_rs2;
	input [5:0] io_enq_bits_1_p_rd;
	input [5:0] io_enq_bits_1_p_rs1;
	input [5:0] io_enq_bits_1_p_rs2;
	input io_enq_bits_1_prs1_ready;
	input io_enq_bits_1_prs2_ready;
	input [5:0] io_enq_bits_1_stale_p_rd;
	input [3:0] io_enq_bits_1_rob_idx;
	input io_enq_bits_1_exception;
	input io_enq_bits_1_pred_taken;
	input [63:0] io_enq_bits_1_pred_target;
	input io_iss_alu_ready;
	output wire io_iss_alu_valid;
	output wire io_iss_alu_bits_valid;
	output wire [63:0] io_iss_alu_bits_pc;
	output wire [31:0] io_iss_alu_bits_inst;
	output wire [5:0] io_iss_alu_bits_fu_code;
	output wire [9:0] io_iss_alu_bits_alu_op;
	output wire [1:0] io_iss_alu_bits_op1_sel;
	output wire [2:0] io_iss_alu_bits_op2_sel;
	output wire [63:0] io_iss_alu_bits_imm;
	output wire [2:0] io_iss_alu_bits_imm_sel;
	output wire io_iss_alu_bits_is_w;
	output wire [2:0] io_iss_alu_bits_mem_cmd;
	output wire [1:0] io_iss_alu_bits_mem_size;
	output wire io_iss_alu_bits_mem_signed;
	output wire [3:0] io_iss_alu_bits_br_type;
	output wire [4:0] io_iss_alu_bits_l_rd;
	output wire [4:0] io_iss_alu_bits_l_rs1;
	output wire [4:0] io_iss_alu_bits_l_rs2;
	output wire io_iss_alu_bits_rf_wen;
	output wire io_iss_alu_bits_use_rs1;
	output wire io_iss_alu_bits_use_rs2;
	output wire [5:0] io_iss_alu_bits_p_rd;
	output wire [5:0] io_iss_alu_bits_p_rs1;
	output wire [5:0] io_iss_alu_bits_p_rs2;
	output wire io_iss_alu_bits_prs1_ready;
	output wire io_iss_alu_bits_prs2_ready;
	output wire [5:0] io_iss_alu_bits_stale_p_rd;
	output wire [3:0] io_iss_alu_bits_rob_idx;
	output wire io_iss_alu_bits_exception;
	output wire io_iss_alu_bits_pred_taken;
	output wire [63:0] io_iss_alu_bits_pred_target;
	input io_iss_lsu_ready;
	output wire io_iss_lsu_valid;
	output wire io_iss_lsu_bits_valid;
	output wire [63:0] io_iss_lsu_bits_pc;
	output wire [31:0] io_iss_lsu_bits_inst;
	output wire [5:0] io_iss_lsu_bits_fu_code;
	output wire [9:0] io_iss_lsu_bits_alu_op;
	output wire [1:0] io_iss_lsu_bits_op1_sel;
	output wire [2:0] io_iss_lsu_bits_op2_sel;
	output wire [63:0] io_iss_lsu_bits_imm;
	output wire [2:0] io_iss_lsu_bits_imm_sel;
	output wire io_iss_lsu_bits_is_w;
	output wire [2:0] io_iss_lsu_bits_mem_cmd;
	output wire [1:0] io_iss_lsu_bits_mem_size;
	output wire io_iss_lsu_bits_mem_signed;
	output wire [3:0] io_iss_lsu_bits_br_type;
	output wire [4:0] io_iss_lsu_bits_l_rd;
	output wire [4:0] io_iss_lsu_bits_l_rs1;
	output wire [4:0] io_iss_lsu_bits_l_rs2;
	output wire io_iss_lsu_bits_rf_wen;
	output wire io_iss_lsu_bits_use_rs1;
	output wire io_iss_lsu_bits_use_rs2;
	output wire [5:0] io_iss_lsu_bits_p_rd;
	output wire [5:0] io_iss_lsu_bits_p_rs1;
	output wire [5:0] io_iss_lsu_bits_p_rs2;
	output wire io_iss_lsu_bits_prs1_ready;
	output wire io_iss_lsu_bits_prs2_ready;
	output wire [5:0] io_iss_lsu_bits_stale_p_rd;
	output wire [3:0] io_iss_lsu_bits_rob_idx;
	output wire io_iss_lsu_bits_exception;
	output wire io_iss_lsu_bits_pred_taken;
	output wire [63:0] io_iss_lsu_bits_pred_target;
	input io_cdb_0_valid;
	input [5:0] io_cdb_0_bits_p_rd;
	input io_cdb_1_valid;
	input [5:0] io_cdb_1_bits_p_rd;
	input io_flush;
	input io_flush_mispredict;
	input [3:0] io_mispredict_rob_idx;
	input [3:0] io_rob_head_idx;
	wire next_rs2_ready_7;
	wire next_rs1_ready_7;
	wire next_rs2_ready_6;
	wire next_rs1_ready_6;
	wire next_rs2_ready_5;
	wire next_rs1_ready_5;
	wire next_rs2_ready_4;
	wire next_rs1_ready_4;
	wire next_rs2_ready_3;
	wire next_rs1_ready_3;
	wire next_rs2_ready_2;
	wire next_rs1_ready_2;
	wire next_rs2_ready_1;
	wire next_rs1_ready_1;
	wire next_rs2_ready_0;
	wire next_rs1_ready_0;
	reg slot_valid_0;
	reg slot_valid_1;
	reg slot_valid_2;
	reg slot_valid_3;
	reg slot_valid_4;
	reg slot_valid_5;
	reg slot_valid_6;
	reg slot_valid_7;
	reg slot_uop_0_valid;
	reg [63:0] slot_uop_0_pc;
	reg [31:0] slot_uop_0_inst;
	reg [5:0] slot_uop_0_fu_code;
	reg [9:0] slot_uop_0_alu_op;
	reg [1:0] slot_uop_0_op1_sel;
	reg [2:0] slot_uop_0_op2_sel;
	reg [63:0] slot_uop_0_imm;
	reg [2:0] slot_uop_0_imm_sel;
	reg slot_uop_0_is_w;
	reg [2:0] slot_uop_0_mem_cmd;
	reg [1:0] slot_uop_0_mem_size;
	reg slot_uop_0_mem_signed;
	reg [3:0] slot_uop_0_br_type;
	reg [4:0] slot_uop_0_l_rd;
	reg [4:0] slot_uop_0_l_rs1;
	reg [4:0] slot_uop_0_l_rs2;
	reg slot_uop_0_rf_wen;
	reg slot_uop_0_use_rs1;
	reg slot_uop_0_use_rs2;
	reg [5:0] slot_uop_0_p_rd;
	reg [5:0] slot_uop_0_p_rs1;
	reg [5:0] slot_uop_0_p_rs2;
	reg slot_uop_0_prs1_ready;
	reg slot_uop_0_prs2_ready;
	reg [5:0] slot_uop_0_stale_p_rd;
	reg [3:0] slot_uop_0_rob_idx;
	reg slot_uop_0_exception;
	reg slot_uop_0_pred_taken;
	reg [63:0] slot_uop_0_pred_target;
	reg slot_uop_1_valid;
	reg [63:0] slot_uop_1_pc;
	reg [31:0] slot_uop_1_inst;
	reg [5:0] slot_uop_1_fu_code;
	reg [9:0] slot_uop_1_alu_op;
	reg [1:0] slot_uop_1_op1_sel;
	reg [2:0] slot_uop_1_op2_sel;
	reg [63:0] slot_uop_1_imm;
	reg [2:0] slot_uop_1_imm_sel;
	reg slot_uop_1_is_w;
	reg [2:0] slot_uop_1_mem_cmd;
	reg [1:0] slot_uop_1_mem_size;
	reg slot_uop_1_mem_signed;
	reg [3:0] slot_uop_1_br_type;
	reg [4:0] slot_uop_1_l_rd;
	reg [4:0] slot_uop_1_l_rs1;
	reg [4:0] slot_uop_1_l_rs2;
	reg slot_uop_1_rf_wen;
	reg slot_uop_1_use_rs1;
	reg slot_uop_1_use_rs2;
	reg [5:0] slot_uop_1_p_rd;
	reg [5:0] slot_uop_1_p_rs1;
	reg [5:0] slot_uop_1_p_rs2;
	reg slot_uop_1_prs1_ready;
	reg slot_uop_1_prs2_ready;
	reg [5:0] slot_uop_1_stale_p_rd;
	reg [3:0] slot_uop_1_rob_idx;
	reg slot_uop_1_exception;
	reg slot_uop_1_pred_taken;
	reg [63:0] slot_uop_1_pred_target;
	reg slot_uop_2_valid;
	reg [63:0] slot_uop_2_pc;
	reg [31:0] slot_uop_2_inst;
	reg [5:0] slot_uop_2_fu_code;
	reg [9:0] slot_uop_2_alu_op;
	reg [1:0] slot_uop_2_op1_sel;
	reg [2:0] slot_uop_2_op2_sel;
	reg [63:0] slot_uop_2_imm;
	reg [2:0] slot_uop_2_imm_sel;
	reg slot_uop_2_is_w;
	reg [2:0] slot_uop_2_mem_cmd;
	reg [1:0] slot_uop_2_mem_size;
	reg slot_uop_2_mem_signed;
	reg [3:0] slot_uop_2_br_type;
	reg [4:0] slot_uop_2_l_rd;
	reg [4:0] slot_uop_2_l_rs1;
	reg [4:0] slot_uop_2_l_rs2;
	reg slot_uop_2_rf_wen;
	reg slot_uop_2_use_rs1;
	reg slot_uop_2_use_rs2;
	reg [5:0] slot_uop_2_p_rd;
	reg [5:0] slot_uop_2_p_rs1;
	reg [5:0] slot_uop_2_p_rs2;
	reg slot_uop_2_prs1_ready;
	reg slot_uop_2_prs2_ready;
	reg [5:0] slot_uop_2_stale_p_rd;
	reg [3:0] slot_uop_2_rob_idx;
	reg slot_uop_2_exception;
	reg slot_uop_2_pred_taken;
	reg [63:0] slot_uop_2_pred_target;
	reg slot_uop_3_valid;
	reg [63:0] slot_uop_3_pc;
	reg [31:0] slot_uop_3_inst;
	reg [5:0] slot_uop_3_fu_code;
	reg [9:0] slot_uop_3_alu_op;
	reg [1:0] slot_uop_3_op1_sel;
	reg [2:0] slot_uop_3_op2_sel;
	reg [63:0] slot_uop_3_imm;
	reg [2:0] slot_uop_3_imm_sel;
	reg slot_uop_3_is_w;
	reg [2:0] slot_uop_3_mem_cmd;
	reg [1:0] slot_uop_3_mem_size;
	reg slot_uop_3_mem_signed;
	reg [3:0] slot_uop_3_br_type;
	reg [4:0] slot_uop_3_l_rd;
	reg [4:0] slot_uop_3_l_rs1;
	reg [4:0] slot_uop_3_l_rs2;
	reg slot_uop_3_rf_wen;
	reg slot_uop_3_use_rs1;
	reg slot_uop_3_use_rs2;
	reg [5:0] slot_uop_3_p_rd;
	reg [5:0] slot_uop_3_p_rs1;
	reg [5:0] slot_uop_3_p_rs2;
	reg slot_uop_3_prs1_ready;
	reg slot_uop_3_prs2_ready;
	reg [5:0] slot_uop_3_stale_p_rd;
	reg [3:0] slot_uop_3_rob_idx;
	reg slot_uop_3_exception;
	reg slot_uop_3_pred_taken;
	reg [63:0] slot_uop_3_pred_target;
	reg slot_uop_4_valid;
	reg [63:0] slot_uop_4_pc;
	reg [31:0] slot_uop_4_inst;
	reg [5:0] slot_uop_4_fu_code;
	reg [9:0] slot_uop_4_alu_op;
	reg [1:0] slot_uop_4_op1_sel;
	reg [2:0] slot_uop_4_op2_sel;
	reg [63:0] slot_uop_4_imm;
	reg [2:0] slot_uop_4_imm_sel;
	reg slot_uop_4_is_w;
	reg [2:0] slot_uop_4_mem_cmd;
	reg [1:0] slot_uop_4_mem_size;
	reg slot_uop_4_mem_signed;
	reg [3:0] slot_uop_4_br_type;
	reg [4:0] slot_uop_4_l_rd;
	reg [4:0] slot_uop_4_l_rs1;
	reg [4:0] slot_uop_4_l_rs2;
	reg slot_uop_4_rf_wen;
	reg slot_uop_4_use_rs1;
	reg slot_uop_4_use_rs2;
	reg [5:0] slot_uop_4_p_rd;
	reg [5:0] slot_uop_4_p_rs1;
	reg [5:0] slot_uop_4_p_rs2;
	reg slot_uop_4_prs1_ready;
	reg slot_uop_4_prs2_ready;
	reg [5:0] slot_uop_4_stale_p_rd;
	reg [3:0] slot_uop_4_rob_idx;
	reg slot_uop_4_exception;
	reg slot_uop_4_pred_taken;
	reg [63:0] slot_uop_4_pred_target;
	reg slot_uop_5_valid;
	reg [63:0] slot_uop_5_pc;
	reg [31:0] slot_uop_5_inst;
	reg [5:0] slot_uop_5_fu_code;
	reg [9:0] slot_uop_5_alu_op;
	reg [1:0] slot_uop_5_op1_sel;
	reg [2:0] slot_uop_5_op2_sel;
	reg [63:0] slot_uop_5_imm;
	reg [2:0] slot_uop_5_imm_sel;
	reg slot_uop_5_is_w;
	reg [2:0] slot_uop_5_mem_cmd;
	reg [1:0] slot_uop_5_mem_size;
	reg slot_uop_5_mem_signed;
	reg [3:0] slot_uop_5_br_type;
	reg [4:0] slot_uop_5_l_rd;
	reg [4:0] slot_uop_5_l_rs1;
	reg [4:0] slot_uop_5_l_rs2;
	reg slot_uop_5_rf_wen;
	reg slot_uop_5_use_rs1;
	reg slot_uop_5_use_rs2;
	reg [5:0] slot_uop_5_p_rd;
	reg [5:0] slot_uop_5_p_rs1;
	reg [5:0] slot_uop_5_p_rs2;
	reg slot_uop_5_prs1_ready;
	reg slot_uop_5_prs2_ready;
	reg [5:0] slot_uop_5_stale_p_rd;
	reg [3:0] slot_uop_5_rob_idx;
	reg slot_uop_5_exception;
	reg slot_uop_5_pred_taken;
	reg [63:0] slot_uop_5_pred_target;
	reg slot_uop_6_valid;
	reg [63:0] slot_uop_6_pc;
	reg [31:0] slot_uop_6_inst;
	reg [5:0] slot_uop_6_fu_code;
	reg [9:0] slot_uop_6_alu_op;
	reg [1:0] slot_uop_6_op1_sel;
	reg [2:0] slot_uop_6_op2_sel;
	reg [63:0] slot_uop_6_imm;
	reg [2:0] slot_uop_6_imm_sel;
	reg slot_uop_6_is_w;
	reg [2:0] slot_uop_6_mem_cmd;
	reg [1:0] slot_uop_6_mem_size;
	reg slot_uop_6_mem_signed;
	reg [3:0] slot_uop_6_br_type;
	reg [4:0] slot_uop_6_l_rd;
	reg [4:0] slot_uop_6_l_rs1;
	reg [4:0] slot_uop_6_l_rs2;
	reg slot_uop_6_rf_wen;
	reg slot_uop_6_use_rs1;
	reg slot_uop_6_use_rs2;
	reg [5:0] slot_uop_6_p_rd;
	reg [5:0] slot_uop_6_p_rs1;
	reg [5:0] slot_uop_6_p_rs2;
	reg slot_uop_6_prs1_ready;
	reg slot_uop_6_prs2_ready;
	reg [5:0] slot_uop_6_stale_p_rd;
	reg [3:0] slot_uop_6_rob_idx;
	reg slot_uop_6_exception;
	reg slot_uop_6_pred_taken;
	reg [63:0] slot_uop_6_pred_target;
	reg slot_uop_7_valid;
	reg [63:0] slot_uop_7_pc;
	reg [31:0] slot_uop_7_inst;
	reg [5:0] slot_uop_7_fu_code;
	reg [9:0] slot_uop_7_alu_op;
	reg [1:0] slot_uop_7_op1_sel;
	reg [2:0] slot_uop_7_op2_sel;
	reg [63:0] slot_uop_7_imm;
	reg [2:0] slot_uop_7_imm_sel;
	reg slot_uop_7_is_w;
	reg [2:0] slot_uop_7_mem_cmd;
	reg [1:0] slot_uop_7_mem_size;
	reg slot_uop_7_mem_signed;
	reg [3:0] slot_uop_7_br_type;
	reg [4:0] slot_uop_7_l_rd;
	reg [4:0] slot_uop_7_l_rs1;
	reg [4:0] slot_uop_7_l_rs2;
	reg slot_uop_7_rf_wen;
	reg slot_uop_7_use_rs1;
	reg slot_uop_7_use_rs2;
	reg [5:0] slot_uop_7_p_rd;
	reg [5:0] slot_uop_7_p_rs1;
	reg [5:0] slot_uop_7_p_rs2;
	reg slot_uop_7_prs1_ready;
	reg slot_uop_7_prs2_ready;
	reg [5:0] slot_uop_7_stale_p_rd;
	reg [3:0] slot_uop_7_rob_idx;
	reg slot_uop_7_exception;
	reg slot_uop_7_pred_taken;
	reg [63:0] slot_uop_7_pred_target;
	reg slot_rs1_ready_0;
	reg slot_rs1_ready_1;
	reg slot_rs1_ready_2;
	reg slot_rs1_ready_3;
	reg slot_rs1_ready_4;
	reg slot_rs1_ready_5;
	reg slot_rs1_ready_6;
	reg slot_rs1_ready_7;
	reg slot_rs2_ready_0;
	reg slot_rs2_ready_1;
	reg slot_rs2_ready_2;
	reg slot_rs2_ready_3;
	reg slot_rs2_ready_4;
	reg slot_rs2_ready_5;
	reg slot_rs2_ready_6;
	reg slot_rs2_ready_7;
	wire [3:0] _is_ghost_now_age_T = slot_uop_0_rob_idx - io_rob_head_idx;
	wire [3:0] _is_ghost_target_age_T_7 = io_mispredict_rob_idx - io_rob_head_idx;
	wire slot_ready_0 = ((slot_valid_0 & ~(io_flush_mispredict & (_is_ghost_now_age_T > _is_ghost_target_age_T_7))) & next_rs1_ready_0) & next_rs2_ready_0;
	wire [3:0] _is_ghost_now_age_T_1 = slot_uop_1_rob_idx - io_rob_head_idx;
	wire slot_ready_1 = ((slot_valid_1 & ~(io_flush_mispredict & (_is_ghost_now_age_T_1 > _is_ghost_target_age_T_7))) & next_rs1_ready_1) & next_rs2_ready_1;
	wire [3:0] _is_ghost_now_age_T_2 = slot_uop_2_rob_idx - io_rob_head_idx;
	wire slot_ready_2 = ((slot_valid_2 & ~(io_flush_mispredict & (_is_ghost_now_age_T_2 > _is_ghost_target_age_T_7))) & next_rs1_ready_2) & next_rs2_ready_2;
	wire [3:0] _is_ghost_now_age_T_3 = slot_uop_3_rob_idx - io_rob_head_idx;
	wire slot_ready_3 = ((slot_valid_3 & ~(io_flush_mispredict & (_is_ghost_now_age_T_3 > _is_ghost_target_age_T_7))) & next_rs1_ready_3) & next_rs2_ready_3;
	wire [3:0] _is_ghost_now_age_T_4 = slot_uop_4_rob_idx - io_rob_head_idx;
	wire slot_ready_4 = ((slot_valid_4 & ~(io_flush_mispredict & (_is_ghost_now_age_T_4 > _is_ghost_target_age_T_7))) & next_rs1_ready_4) & next_rs2_ready_4;
	wire [3:0] _is_ghost_now_age_T_5 = slot_uop_5_rob_idx - io_rob_head_idx;
	wire slot_ready_5 = ((slot_valid_5 & ~(io_flush_mispredict & (_is_ghost_now_age_T_5 > _is_ghost_target_age_T_7))) & next_rs1_ready_5) & next_rs2_ready_5;
	wire [3:0] _is_ghost_now_age_T_6 = slot_uop_6_rob_idx - io_rob_head_idx;
	wire slot_ready_6 = ((slot_valid_6 & ~(io_flush_mispredict & (_is_ghost_now_age_T_6 > _is_ghost_target_age_T_7))) & next_rs1_ready_6) & next_rs2_ready_6;
	wire [3:0] _is_ghost_now_age_T_7 = slot_uop_7_rob_idx - io_rob_head_idx;
	wire slot_ready_7 = ((slot_valid_7 & ~(io_flush_mispredict & (_is_ghost_now_age_T_7 > _is_ghost_target_age_T_7))) & next_rs1_ready_7) & next_rs2_ready_7;
	wire alu_reqs_0 = slot_ready_0 & ((slot_uop_0_fu_code == 6'h00) | (slot_uop_0_fu_code == 6'h02));
	wire lsu_reqs_0 = slot_ready_0 & (slot_uop_0_fu_code == 6'h01);
	wire alu_reqs_1 = slot_ready_1 & ((slot_uop_1_fu_code == 6'h00) | (slot_uop_1_fu_code == 6'h02));
	wire lsu_reqs_1 = slot_ready_1 & (slot_uop_1_fu_code == 6'h01);
	wire alu_reqs_2 = slot_ready_2 & ((slot_uop_2_fu_code == 6'h00) | (slot_uop_2_fu_code == 6'h02));
	wire lsu_reqs_2 = slot_ready_2 & (slot_uop_2_fu_code == 6'h01);
	wire alu_reqs_3 = slot_ready_3 & ((slot_uop_3_fu_code == 6'h00) | (slot_uop_3_fu_code == 6'h02));
	wire lsu_reqs_3 = slot_ready_3 & (slot_uop_3_fu_code == 6'h01);
	wire alu_reqs_4 = slot_ready_4 & ((slot_uop_4_fu_code == 6'h00) | (slot_uop_4_fu_code == 6'h02));
	wire lsu_reqs_4 = slot_ready_4 & (slot_uop_4_fu_code == 6'h01);
	wire alu_reqs_5 = slot_ready_5 & ((slot_uop_5_fu_code == 6'h00) | (slot_uop_5_fu_code == 6'h02));
	wire lsu_reqs_5 = slot_ready_5 & (slot_uop_5_fu_code == 6'h01);
	wire alu_reqs_6 = slot_ready_6 & ((slot_uop_6_fu_code == 6'h00) | (slot_uop_6_fu_code == 6'h02));
	wire lsu_reqs_6 = slot_ready_6 & (slot_uop_6_fu_code == 6'h01);
	wire [2:0] sel_alu_idx = (alu_reqs_0 ? 3'h0 : (alu_reqs_1 ? 3'h1 : (alu_reqs_2 ? 3'h2 : (alu_reqs_3 ? 3'h3 : (alu_reqs_4 ? 3'h4 : (alu_reqs_5 ? 3'h5 : {2'h3, ~alu_reqs_6}))))));
	wire [2:0] sel_lsu_idx = (lsu_reqs_0 ? 3'h0 : (lsu_reqs_1 ? 3'h1 : (lsu_reqs_2 ? 3'h2 : (lsu_reqs_3 ? 3'h3 : (lsu_reqs_4 ? 3'h4 : (lsu_reqs_5 ? 3'h5 : {2'h3, ~lsu_reqs_6}))))));
	wire [7:0] _can_iss_alu_T = {slot_ready_7 & ((slot_uop_7_fu_code == 6'h00) | (slot_uop_7_fu_code == 6'h02)), alu_reqs_6, alu_reqs_5, alu_reqs_4, alu_reqs_3, alu_reqs_2, alu_reqs_1, alu_reqs_0};
	wire [7:0] _can_iss_lsu_T = {slot_ready_7 & (slot_uop_7_fu_code == 6'h01), lsu_reqs_6, lsu_reqs_5, lsu_reqs_4, lsu_reqs_3, lsu_reqs_2, lsu_reqs_1, lsu_reqs_0};
	wire [2:0] alloc_idx_0 = (slot_valid_0 ? (slot_valid_1 ? (slot_valid_2 ? (slot_valid_3 ? (slot_valid_4 ? (slot_valid_5 ? {2'h3, slot_valid_6} : 3'h5) : 3'h4) : 3'h3) : 3'h2) : 3'h1) : 3'h0);
	wire free_slots_marks1_0 = ~slot_valid_0 & |alloc_idx_0;
	wire free_slots_marks1_1 = ~slot_valid_1 & (alloc_idx_0 != 3'h1);
	wire free_slots_marks1_2 = ~slot_valid_2 & (alloc_idx_0 != 3'h2);
	wire free_slots_marks1_3 = ~slot_valid_3 & (alloc_idx_0 != 3'h3);
	wire free_slots_marks1_4 = ~slot_valid_4 & (alloc_idx_0 != 3'h4);
	wire free_slots_marks1_5 = ~slot_valid_5 & (alloc_idx_0 != 3'h5);
	wire free_slots_marks1_6 = ~slot_valid_6 & (alloc_idx_0 != 3'h6);
	wire need_2 = io_enq_bits_0_valid & io_enq_bits_1_valid;
	wire io_enq_ready_0 = (need_2 ? ((((((free_slots_marks1_0 | free_slots_marks1_1) | free_slots_marks1_2) | free_slots_marks1_3) | free_slots_marks1_4) | free_slots_marks1_5) | free_slots_marks1_6) | (~slot_valid_7 & (alloc_idx_0 != 3'h7)) : ((((((((io_enq_bits_0_valid ^ ~io_enq_bits_1_valid) | ~slot_valid_0) | ~slot_valid_1) | ~slot_valid_2) | ~slot_valid_3) | ~slot_valid_4) | ~slot_valid_5) | ~slot_valid_6) | ~slot_valid_7) & ~io_flush_mispredict;
	wire _GEN = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_0_p_rs1)) & |slot_uop_0_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_0_p_rs1)) & |slot_uop_0_p_rs1);
	assign next_rs1_ready_0 = _GEN | slot_rs1_ready_0;
	wire _GEN_0 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_0_p_rs2)) & |slot_uop_0_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_0_p_rs2)) & |slot_uop_0_p_rs2);
	assign next_rs2_ready_0 = _GEN_0 | slot_rs2_ready_0;
	wire _GEN_1 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_1_p_rs1)) & |slot_uop_1_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_1_p_rs1)) & |slot_uop_1_p_rs1);
	assign next_rs1_ready_1 = _GEN_1 | slot_rs1_ready_1;
	wire _GEN_2 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_1_p_rs2)) & |slot_uop_1_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_1_p_rs2)) & |slot_uop_1_p_rs2);
	assign next_rs2_ready_1 = _GEN_2 | slot_rs2_ready_1;
	wire _GEN_3 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_2_p_rs1)) & |slot_uop_2_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_2_p_rs1)) & |slot_uop_2_p_rs1);
	assign next_rs1_ready_2 = _GEN_3 | slot_rs1_ready_2;
	wire _GEN_4 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_2_p_rs2)) & |slot_uop_2_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_2_p_rs2)) & |slot_uop_2_p_rs2);
	assign next_rs2_ready_2 = _GEN_4 | slot_rs2_ready_2;
	wire _GEN_5 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_3_p_rs1)) & |slot_uop_3_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_3_p_rs1)) & |slot_uop_3_p_rs1);
	assign next_rs1_ready_3 = _GEN_5 | slot_rs1_ready_3;
	wire _GEN_6 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_3_p_rs2)) & |slot_uop_3_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_3_p_rs2)) & |slot_uop_3_p_rs2);
	assign next_rs2_ready_3 = _GEN_6 | slot_rs2_ready_3;
	wire _GEN_7 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_4_p_rs1)) & |slot_uop_4_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_4_p_rs1)) & |slot_uop_4_p_rs1);
	assign next_rs1_ready_4 = _GEN_7 | slot_rs1_ready_4;
	wire _GEN_8 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_4_p_rs2)) & |slot_uop_4_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_4_p_rs2)) & |slot_uop_4_p_rs2);
	assign next_rs2_ready_4 = _GEN_8 | slot_rs2_ready_4;
	wire _GEN_9 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_5_p_rs1)) & |slot_uop_5_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_5_p_rs1)) & |slot_uop_5_p_rs1);
	assign next_rs1_ready_5 = _GEN_9 | slot_rs1_ready_5;
	wire _GEN_10 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_5_p_rs2)) & |slot_uop_5_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_5_p_rs2)) & |slot_uop_5_p_rs2);
	assign next_rs2_ready_5 = _GEN_10 | slot_rs2_ready_5;
	wire _GEN_11 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_6_p_rs1)) & |slot_uop_6_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_6_p_rs1)) & |slot_uop_6_p_rs1);
	assign next_rs1_ready_6 = _GEN_11 | slot_rs1_ready_6;
	wire _GEN_12 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_6_p_rs2)) & |slot_uop_6_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_6_p_rs2)) & |slot_uop_6_p_rs2);
	assign next_rs2_ready_6 = _GEN_12 | slot_rs2_ready_6;
	wire _GEN_13 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_7_p_rs1)) & |slot_uop_7_p_rs1) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_7_p_rs1)) & |slot_uop_7_p_rs1);
	assign next_rs1_ready_7 = _GEN_13 | slot_rs1_ready_7;
	wire _GEN_14 = ((io_cdb_0_valid & (io_cdb_0_bits_p_rd == slot_uop_7_p_rs2)) & |slot_uop_7_p_rs2) | ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == slot_uop_7_p_rs2)) & |slot_uop_7_p_rs2);
	assign next_rs2_ready_7 = _GEN_14 | slot_rs2_ready_7;
	wire [7:0] _GEN_15 = {slot_uop_7_valid, slot_uop_6_valid, slot_uop_5_valid, slot_uop_4_valid, slot_uop_3_valid, slot_uop_2_valid, slot_uop_1_valid, slot_uop_0_valid};
	wire [511:0] _GEN_16 = {slot_uop_7_pc, slot_uop_6_pc, slot_uop_5_pc, slot_uop_4_pc, slot_uop_3_pc, slot_uop_2_pc, slot_uop_1_pc, slot_uop_0_pc};
	wire [255:0] _GEN_17 = {slot_uop_7_inst, slot_uop_6_inst, slot_uop_5_inst, slot_uop_4_inst, slot_uop_3_inst, slot_uop_2_inst, slot_uop_1_inst, slot_uop_0_inst};
	wire [47:0] _GEN_18 = {slot_uop_7_fu_code, slot_uop_6_fu_code, slot_uop_5_fu_code, slot_uop_4_fu_code, slot_uop_3_fu_code, slot_uop_2_fu_code, slot_uop_1_fu_code, slot_uop_0_fu_code};
	wire [79:0] _GEN_19 = {slot_uop_7_alu_op, slot_uop_6_alu_op, slot_uop_5_alu_op, slot_uop_4_alu_op, slot_uop_3_alu_op, slot_uop_2_alu_op, slot_uop_1_alu_op, slot_uop_0_alu_op};
	wire [15:0] _GEN_20 = {slot_uop_7_op1_sel, slot_uop_6_op1_sel, slot_uop_5_op1_sel, slot_uop_4_op1_sel, slot_uop_3_op1_sel, slot_uop_2_op1_sel, slot_uop_1_op1_sel, slot_uop_0_op1_sel};
	wire [23:0] _GEN_21 = {slot_uop_7_op2_sel, slot_uop_6_op2_sel, slot_uop_5_op2_sel, slot_uop_4_op2_sel, slot_uop_3_op2_sel, slot_uop_2_op2_sel, slot_uop_1_op2_sel, slot_uop_0_op2_sel};
	wire [511:0] _GEN_22 = {slot_uop_7_imm, slot_uop_6_imm, slot_uop_5_imm, slot_uop_4_imm, slot_uop_3_imm, slot_uop_2_imm, slot_uop_1_imm, slot_uop_0_imm};
	wire [23:0] _GEN_23 = {slot_uop_7_imm_sel, slot_uop_6_imm_sel, slot_uop_5_imm_sel, slot_uop_4_imm_sel, slot_uop_3_imm_sel, slot_uop_2_imm_sel, slot_uop_1_imm_sel, slot_uop_0_imm_sel};
	wire [7:0] _GEN_24 = {slot_uop_7_is_w, slot_uop_6_is_w, slot_uop_5_is_w, slot_uop_4_is_w, slot_uop_3_is_w, slot_uop_2_is_w, slot_uop_1_is_w, slot_uop_0_is_w};
	wire [23:0] _GEN_25 = {slot_uop_7_mem_cmd, slot_uop_6_mem_cmd, slot_uop_5_mem_cmd, slot_uop_4_mem_cmd, slot_uop_3_mem_cmd, slot_uop_2_mem_cmd, slot_uop_1_mem_cmd, slot_uop_0_mem_cmd};
	wire [15:0] _GEN_26 = {slot_uop_7_mem_size, slot_uop_6_mem_size, slot_uop_5_mem_size, slot_uop_4_mem_size, slot_uop_3_mem_size, slot_uop_2_mem_size, slot_uop_1_mem_size, slot_uop_0_mem_size};
	wire [7:0] _GEN_27 = {slot_uop_7_mem_signed, slot_uop_6_mem_signed, slot_uop_5_mem_signed, slot_uop_4_mem_signed, slot_uop_3_mem_signed, slot_uop_2_mem_signed, slot_uop_1_mem_signed, slot_uop_0_mem_signed};
	wire [31:0] _GEN_28 = {slot_uop_7_br_type, slot_uop_6_br_type, slot_uop_5_br_type, slot_uop_4_br_type, slot_uop_3_br_type, slot_uop_2_br_type, slot_uop_1_br_type, slot_uop_0_br_type};
	wire [39:0] _GEN_29 = {slot_uop_7_l_rd, slot_uop_6_l_rd, slot_uop_5_l_rd, slot_uop_4_l_rd, slot_uop_3_l_rd, slot_uop_2_l_rd, slot_uop_1_l_rd, slot_uop_0_l_rd};
	wire [39:0] _GEN_30 = {slot_uop_7_l_rs1, slot_uop_6_l_rs1, slot_uop_5_l_rs1, slot_uop_4_l_rs1, slot_uop_3_l_rs1, slot_uop_2_l_rs1, slot_uop_1_l_rs1, slot_uop_0_l_rs1};
	wire [39:0] _GEN_31 = {slot_uop_7_l_rs2, slot_uop_6_l_rs2, slot_uop_5_l_rs2, slot_uop_4_l_rs2, slot_uop_3_l_rs2, slot_uop_2_l_rs2, slot_uop_1_l_rs2, slot_uop_0_l_rs2};
	wire [7:0] _GEN_32 = {slot_uop_7_rf_wen, slot_uop_6_rf_wen, slot_uop_5_rf_wen, slot_uop_4_rf_wen, slot_uop_3_rf_wen, slot_uop_2_rf_wen, slot_uop_1_rf_wen, slot_uop_0_rf_wen};
	wire [7:0] _GEN_33 = {slot_uop_7_use_rs1, slot_uop_6_use_rs1, slot_uop_5_use_rs1, slot_uop_4_use_rs1, slot_uop_3_use_rs1, slot_uop_2_use_rs1, slot_uop_1_use_rs1, slot_uop_0_use_rs1};
	wire [7:0] _GEN_34 = {slot_uop_7_use_rs2, slot_uop_6_use_rs2, slot_uop_5_use_rs2, slot_uop_4_use_rs2, slot_uop_3_use_rs2, slot_uop_2_use_rs2, slot_uop_1_use_rs2, slot_uop_0_use_rs2};
	wire [47:0] _GEN_35 = {slot_uop_7_p_rd, slot_uop_6_p_rd, slot_uop_5_p_rd, slot_uop_4_p_rd, slot_uop_3_p_rd, slot_uop_2_p_rd, slot_uop_1_p_rd, slot_uop_0_p_rd};
	wire [47:0] _GEN_36 = {slot_uop_7_p_rs1, slot_uop_6_p_rs1, slot_uop_5_p_rs1, slot_uop_4_p_rs1, slot_uop_3_p_rs1, slot_uop_2_p_rs1, slot_uop_1_p_rs1, slot_uop_0_p_rs1};
	wire [47:0] _GEN_37 = {slot_uop_7_p_rs2, slot_uop_6_p_rs2, slot_uop_5_p_rs2, slot_uop_4_p_rs2, slot_uop_3_p_rs2, slot_uop_2_p_rs2, slot_uop_1_p_rs2, slot_uop_0_p_rs2};
	wire [7:0] _GEN_38 = {slot_uop_7_prs1_ready, slot_uop_6_prs1_ready, slot_uop_5_prs1_ready, slot_uop_4_prs1_ready, slot_uop_3_prs1_ready, slot_uop_2_prs1_ready, slot_uop_1_prs1_ready, slot_uop_0_prs1_ready};
	wire [7:0] _GEN_39 = {slot_uop_7_prs2_ready, slot_uop_6_prs2_ready, slot_uop_5_prs2_ready, slot_uop_4_prs2_ready, slot_uop_3_prs2_ready, slot_uop_2_prs2_ready, slot_uop_1_prs2_ready, slot_uop_0_prs2_ready};
	wire [47:0] _GEN_40 = {slot_uop_7_stale_p_rd, slot_uop_6_stale_p_rd, slot_uop_5_stale_p_rd, slot_uop_4_stale_p_rd, slot_uop_3_stale_p_rd, slot_uop_2_stale_p_rd, slot_uop_1_stale_p_rd, slot_uop_0_stale_p_rd};
	wire [31:0] _GEN_41 = {slot_uop_7_rob_idx, slot_uop_6_rob_idx, slot_uop_5_rob_idx, slot_uop_4_rob_idx, slot_uop_3_rob_idx, slot_uop_2_rob_idx, slot_uop_1_rob_idx, slot_uop_0_rob_idx};
	wire [7:0] _GEN_42 = {slot_uop_7_exception, slot_uop_6_exception, slot_uop_5_exception, slot_uop_4_exception, slot_uop_3_exception, slot_uop_2_exception, slot_uop_1_exception, slot_uop_0_exception};
	wire [7:0] _GEN_43 = {slot_uop_7_pred_taken, slot_uop_6_pred_taken, slot_uop_5_pred_taken, slot_uop_4_pred_taken, slot_uop_3_pred_taken, slot_uop_2_pred_taken, slot_uop_1_pred_taken, slot_uop_0_pred_taken};
	wire [511:0] _GEN_44 = {slot_uop_7_pred_target, slot_uop_6_pred_target, slot_uop_5_pred_target, slot_uop_4_pred_target, slot_uop_3_pred_target, slot_uop_2_pred_target, slot_uop_1_pred_target, slot_uop_0_pred_target};
	always @(posedge clock) begin : sv2v_autoblock_1
		reg [2:0] alloc_idx_1;
		reg do_alloc;
		reg do_iss_alu;
		reg do_iss_lsu;
		reg _is_alloc_0_T_14;
		reg is_alloc_0;
		reg _is_alloc_1_T_14;
		reg is_this_alloc;
		reg is_this_issued;
		reg is_alloc_0_1;
		reg is_this_alloc_1;
		reg is_this_issued_1;
		reg is_alloc_0_2;
		reg is_this_alloc_2;
		reg is_this_issued_2;
		reg is_alloc_0_3;
		reg is_this_alloc_3;
		reg is_this_issued_3;
		reg is_alloc_0_4;
		reg is_this_alloc_4;
		reg is_this_issued_4;
		reg is_alloc_0_5;
		reg is_this_alloc_5;
		reg is_this_issued_5;
		reg is_alloc_0_6;
		reg is_this_alloc_6;
		reg is_this_issued_6;
		reg is_alloc_0_7;
		reg is_this_alloc_7;
		reg is_this_issued_7;
		alloc_idx_1 = (free_slots_marks1_0 ? 3'h0 : (free_slots_marks1_1 ? 3'h1 : (free_slots_marks1_2 ? 3'h2 : (free_slots_marks1_3 ? 3'h3 : (free_slots_marks1_4 ? 3'h4 : (free_slots_marks1_5 ? 3'h5 : {2'h3, ~free_slots_marks1_6}))))));
		do_alloc = (io_enq_ready_0 & io_enq_valid) & ~io_flush_mispredict;
		do_iss_alu = io_iss_alu_ready & |_can_iss_alu_T;
		do_iss_lsu = io_iss_lsu_ready & |_can_iss_lsu_T;
		_is_alloc_0_T_14 = do_alloc & (io_enq_bits_0_valid | io_enq_bits_1_valid);
		_is_alloc_1_T_14 = do_alloc & need_2;
		is_alloc_0 = _is_alloc_0_T_14 & (alloc_idx_0 == 3'h0);
		is_this_alloc = is_alloc_0 | (_is_alloc_1_T_14 & (alloc_idx_1 == 3'h0));
		is_this_issued = (do_iss_alu & (sel_alu_idx == 3'h0)) | (do_iss_lsu & (sel_lsu_idx == 3'h0));
		is_alloc_0_1 = _is_alloc_0_T_14 & (alloc_idx_0 == 3'h1);
		is_this_alloc_1 = is_alloc_0_1 | (_is_alloc_1_T_14 & (alloc_idx_1 == 3'h1));
		is_this_issued_1 = (do_iss_alu & (sel_alu_idx == 3'h1)) | (do_iss_lsu & (sel_lsu_idx == 3'h1));
		is_alloc_0_2 = _is_alloc_0_T_14 & (alloc_idx_0 == 3'h2);
		is_this_alloc_2 = is_alloc_0_2 | (_is_alloc_1_T_14 & (alloc_idx_1 == 3'h2));
		is_this_issued_2 = (do_iss_alu & (sel_alu_idx == 3'h2)) | (do_iss_lsu & (sel_lsu_idx == 3'h2));
		is_alloc_0_3 = _is_alloc_0_T_14 & (alloc_idx_0 == 3'h3);
		is_this_alloc_3 = is_alloc_0_3 | (_is_alloc_1_T_14 & (alloc_idx_1 == 3'h3));
		is_this_issued_3 = (do_iss_alu & (sel_alu_idx == 3'h3)) | (do_iss_lsu & (sel_lsu_idx == 3'h3));
		is_alloc_0_4 = _is_alloc_0_T_14 & (alloc_idx_0 == 3'h4);
		is_this_alloc_4 = is_alloc_0_4 | (_is_alloc_1_T_14 & (alloc_idx_1 == 3'h4));
		is_this_issued_4 = (do_iss_alu & (sel_alu_idx == 3'h4)) | (do_iss_lsu & (sel_lsu_idx == 3'h4));
		is_alloc_0_5 = _is_alloc_0_T_14 & (alloc_idx_0 == 3'h5);
		is_this_alloc_5 = is_alloc_0_5 | (_is_alloc_1_T_14 & (alloc_idx_1 == 3'h5));
		is_this_issued_5 = (do_iss_alu & (sel_alu_idx == 3'h5)) | (do_iss_lsu & (sel_lsu_idx == 3'h5));
		is_alloc_0_6 = _is_alloc_0_T_14 & (alloc_idx_0 == 3'h6);
		is_this_alloc_6 = is_alloc_0_6 | (_is_alloc_1_T_14 & (alloc_idx_1 == 3'h6));
		is_this_issued_6 = (do_iss_alu & (sel_alu_idx == 3'h6)) | (do_iss_lsu & (sel_lsu_idx == 3'h6));
		is_alloc_0_7 = _is_alloc_0_T_14 & (&alloc_idx_0);
		is_this_alloc_7 = is_alloc_0_7 | (_is_alloc_1_T_14 & (&alloc_idx_1));
		is_this_issued_7 = (do_iss_alu & (&sel_alu_idx)) | (do_iss_lsu & (&sel_lsu_idx));
		if (reset) begin
			slot_valid_0 <= 1'h0;
			slot_valid_1 <= 1'h0;
			slot_valid_2 <= 1'h0;
			slot_valid_3 <= 1'h0;
			slot_valid_4 <= 1'h0;
			slot_valid_5 <= 1'h0;
			slot_valid_6 <= 1'h0;
			slot_valid_7 <= 1'h0;
		end
		else begin
			slot_valid_0 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T > _is_ghost_target_age_T_7))) | is_this_issued) & (is_this_alloc | slot_valid_0);
			slot_valid_1 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T_1 > _is_ghost_target_age_T_7))) | is_this_issued_1) & (is_this_alloc_1 | slot_valid_1);
			slot_valid_2 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T_2 > _is_ghost_target_age_T_7))) | is_this_issued_2) & (is_this_alloc_2 | slot_valid_2);
			slot_valid_3 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T_3 > _is_ghost_target_age_T_7))) | is_this_issued_3) & (is_this_alloc_3 | slot_valid_3);
			slot_valid_4 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T_4 > _is_ghost_target_age_T_7))) | is_this_issued_4) & (is_this_alloc_4 | slot_valid_4);
			slot_valid_5 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T_5 > _is_ghost_target_age_T_7))) | is_this_issued_5) & (is_this_alloc_5 | slot_valid_5);
			slot_valid_6 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T_6 > _is_ghost_target_age_T_7))) | is_this_issued_6) & (is_this_alloc_6 | slot_valid_6);
			slot_valid_7 <= ~((io_flush | (io_flush_mispredict & (_is_ghost_now_age_T_7 > _is_ghost_target_age_T_7))) | is_this_issued_7) & (is_this_alloc_7 | slot_valid_7);
		end
		if (is_this_alloc) begin : sv2v_autoblock_2
			reg _GEN_45;
			reg alloc_uop_use_rs1;
			reg alloc_uop_use_rs2;
			reg alloc_uop_prs1_ready;
			reg alloc_uop_prs2_ready;
			_GEN_45 = is_alloc_0 & io_enq_bits_0_valid;
			alloc_uop_use_rs1 = (_GEN_45 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_use_rs2 = (_GEN_45 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_prs1_ready = (_GEN_45 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_prs2_ready = (_GEN_45 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_0_valid <= (_GEN_45 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_0_pc <= (_GEN_45 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_0_inst <= (_GEN_45 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_0_fu_code <= (_GEN_45 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_0_alu_op <= (_GEN_45 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_0_op1_sel <= (_GEN_45 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_0_op2_sel <= (_GEN_45 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_0_imm <= (_GEN_45 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_0_imm_sel <= (_GEN_45 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_0_is_w <= (_GEN_45 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_0_mem_cmd <= (_GEN_45 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_0_mem_size <= (_GEN_45 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_0_mem_signed <= (_GEN_45 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_0_br_type <= (_GEN_45 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_0_l_rd <= (_GEN_45 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_0_l_rs1 <= (_GEN_45 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_0_l_rs2 <= (_GEN_45 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_0_rf_wen <= (_GEN_45 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_0_use_rs1 <= alloc_uop_use_rs1;
			slot_uop_0_use_rs2 <= alloc_uop_use_rs2;
			slot_uop_0_p_rd <= (_GEN_45 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_0_p_rs1 <= (_GEN_45 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_0_p_rs2 <= (_GEN_45 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_0_prs1_ready <= alloc_uop_prs1_ready;
			slot_uop_0_prs2_ready <= alloc_uop_prs2_ready;
			slot_uop_0_stale_p_rd <= (_GEN_45 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_0_rob_idx <= (_GEN_45 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_0_exception <= (_GEN_45 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_0_pred_taken <= (_GEN_45 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_0_pred_target <= (_GEN_45 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_0 <= ~alloc_uop_use_rs1 | alloc_uop_prs1_ready;
			slot_rs2_ready_0 <= ~alloc_uop_use_rs2 | alloc_uop_prs2_ready;
		end
		else begin
			slot_rs1_ready_0 <= (~is_this_issued & _GEN) | slot_rs1_ready_0;
			slot_rs2_ready_0 <= (~is_this_issued & _GEN_0) | slot_rs2_ready_0;
		end
		if (is_this_alloc_1) begin : sv2v_autoblock_3
			reg _GEN_46;
			reg alloc_uop_1_use_rs1;
			reg alloc_uop_1_use_rs2;
			reg alloc_uop_1_prs1_ready;
			reg alloc_uop_1_prs2_ready;
			_GEN_46 = is_alloc_0_1 & io_enq_bits_0_valid;
			alloc_uop_1_use_rs1 = (_GEN_46 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_1_use_rs2 = (_GEN_46 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_1_prs1_ready = (_GEN_46 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_1_prs2_ready = (_GEN_46 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_1_valid <= (_GEN_46 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_1_pc <= (_GEN_46 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_1_inst <= (_GEN_46 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_1_fu_code <= (_GEN_46 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_1_alu_op <= (_GEN_46 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_1_op1_sel <= (_GEN_46 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_1_op2_sel <= (_GEN_46 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_1_imm <= (_GEN_46 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_1_imm_sel <= (_GEN_46 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_1_is_w <= (_GEN_46 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_1_mem_cmd <= (_GEN_46 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_1_mem_size <= (_GEN_46 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_1_mem_signed <= (_GEN_46 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_1_br_type <= (_GEN_46 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_1_l_rd <= (_GEN_46 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_1_l_rs1 <= (_GEN_46 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_1_l_rs2 <= (_GEN_46 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_1_rf_wen <= (_GEN_46 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_1_use_rs1 <= alloc_uop_1_use_rs1;
			slot_uop_1_use_rs2 <= alloc_uop_1_use_rs2;
			slot_uop_1_p_rd <= (_GEN_46 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_1_p_rs1 <= (_GEN_46 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_1_p_rs2 <= (_GEN_46 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_1_prs1_ready <= alloc_uop_1_prs1_ready;
			slot_uop_1_prs2_ready <= alloc_uop_1_prs2_ready;
			slot_uop_1_stale_p_rd <= (_GEN_46 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_1_rob_idx <= (_GEN_46 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_1_exception <= (_GEN_46 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_1_pred_taken <= (_GEN_46 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_1_pred_target <= (_GEN_46 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_1 <= ~alloc_uop_1_use_rs1 | alloc_uop_1_prs1_ready;
			slot_rs2_ready_1 <= ~alloc_uop_1_use_rs2 | alloc_uop_1_prs2_ready;
		end
		else begin
			slot_rs1_ready_1 <= (~is_this_issued_1 & _GEN_1) | slot_rs1_ready_1;
			slot_rs2_ready_1 <= (~is_this_issued_1 & _GEN_2) | slot_rs2_ready_1;
		end
		if (is_this_alloc_2) begin : sv2v_autoblock_4
			reg _GEN_47;
			reg alloc_uop_2_use_rs1;
			reg alloc_uop_2_use_rs2;
			reg alloc_uop_2_prs1_ready;
			reg alloc_uop_2_prs2_ready;
			_GEN_47 = is_alloc_0_2 & io_enq_bits_0_valid;
			alloc_uop_2_use_rs1 = (_GEN_47 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_2_use_rs2 = (_GEN_47 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_2_prs1_ready = (_GEN_47 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_2_prs2_ready = (_GEN_47 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_2_valid <= (_GEN_47 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_2_pc <= (_GEN_47 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_2_inst <= (_GEN_47 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_2_fu_code <= (_GEN_47 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_2_alu_op <= (_GEN_47 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_2_op1_sel <= (_GEN_47 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_2_op2_sel <= (_GEN_47 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_2_imm <= (_GEN_47 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_2_imm_sel <= (_GEN_47 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_2_is_w <= (_GEN_47 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_2_mem_cmd <= (_GEN_47 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_2_mem_size <= (_GEN_47 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_2_mem_signed <= (_GEN_47 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_2_br_type <= (_GEN_47 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_2_l_rd <= (_GEN_47 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_2_l_rs1 <= (_GEN_47 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_2_l_rs2 <= (_GEN_47 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_2_rf_wen <= (_GEN_47 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_2_use_rs1 <= alloc_uop_2_use_rs1;
			slot_uop_2_use_rs2 <= alloc_uop_2_use_rs2;
			slot_uop_2_p_rd <= (_GEN_47 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_2_p_rs1 <= (_GEN_47 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_2_p_rs2 <= (_GEN_47 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_2_prs1_ready <= alloc_uop_2_prs1_ready;
			slot_uop_2_prs2_ready <= alloc_uop_2_prs2_ready;
			slot_uop_2_stale_p_rd <= (_GEN_47 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_2_rob_idx <= (_GEN_47 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_2_exception <= (_GEN_47 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_2_pred_taken <= (_GEN_47 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_2_pred_target <= (_GEN_47 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_2 <= ~alloc_uop_2_use_rs1 | alloc_uop_2_prs1_ready;
			slot_rs2_ready_2 <= ~alloc_uop_2_use_rs2 | alloc_uop_2_prs2_ready;
		end
		else begin
			slot_rs1_ready_2 <= (~is_this_issued_2 & _GEN_3) | slot_rs1_ready_2;
			slot_rs2_ready_2 <= (~is_this_issued_2 & _GEN_4) | slot_rs2_ready_2;
		end
		if (is_this_alloc_3) begin : sv2v_autoblock_5
			reg _GEN_48;
			reg alloc_uop_3_use_rs1;
			reg alloc_uop_3_use_rs2;
			reg alloc_uop_3_prs1_ready;
			reg alloc_uop_3_prs2_ready;
			_GEN_48 = is_alloc_0_3 & io_enq_bits_0_valid;
			alloc_uop_3_use_rs1 = (_GEN_48 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_3_use_rs2 = (_GEN_48 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_3_prs1_ready = (_GEN_48 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_3_prs2_ready = (_GEN_48 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_3_valid <= (_GEN_48 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_3_pc <= (_GEN_48 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_3_inst <= (_GEN_48 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_3_fu_code <= (_GEN_48 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_3_alu_op <= (_GEN_48 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_3_op1_sel <= (_GEN_48 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_3_op2_sel <= (_GEN_48 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_3_imm <= (_GEN_48 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_3_imm_sel <= (_GEN_48 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_3_is_w <= (_GEN_48 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_3_mem_cmd <= (_GEN_48 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_3_mem_size <= (_GEN_48 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_3_mem_signed <= (_GEN_48 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_3_br_type <= (_GEN_48 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_3_l_rd <= (_GEN_48 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_3_l_rs1 <= (_GEN_48 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_3_l_rs2 <= (_GEN_48 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_3_rf_wen <= (_GEN_48 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_3_use_rs1 <= alloc_uop_3_use_rs1;
			slot_uop_3_use_rs2 <= alloc_uop_3_use_rs2;
			slot_uop_3_p_rd <= (_GEN_48 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_3_p_rs1 <= (_GEN_48 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_3_p_rs2 <= (_GEN_48 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_3_prs1_ready <= alloc_uop_3_prs1_ready;
			slot_uop_3_prs2_ready <= alloc_uop_3_prs2_ready;
			slot_uop_3_stale_p_rd <= (_GEN_48 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_3_rob_idx <= (_GEN_48 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_3_exception <= (_GEN_48 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_3_pred_taken <= (_GEN_48 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_3_pred_target <= (_GEN_48 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_3 <= ~alloc_uop_3_use_rs1 | alloc_uop_3_prs1_ready;
			slot_rs2_ready_3 <= ~alloc_uop_3_use_rs2 | alloc_uop_3_prs2_ready;
		end
		else begin
			slot_rs1_ready_3 <= (~is_this_issued_3 & _GEN_5) | slot_rs1_ready_3;
			slot_rs2_ready_3 <= (~is_this_issued_3 & _GEN_6) | slot_rs2_ready_3;
		end
		if (is_this_alloc_4) begin : sv2v_autoblock_6
			reg _GEN_49;
			reg alloc_uop_4_use_rs1;
			reg alloc_uop_4_use_rs2;
			reg alloc_uop_4_prs1_ready;
			reg alloc_uop_4_prs2_ready;
			_GEN_49 = is_alloc_0_4 & io_enq_bits_0_valid;
			alloc_uop_4_use_rs1 = (_GEN_49 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_4_use_rs2 = (_GEN_49 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_4_prs1_ready = (_GEN_49 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_4_prs2_ready = (_GEN_49 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_4_valid <= (_GEN_49 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_4_pc <= (_GEN_49 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_4_inst <= (_GEN_49 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_4_fu_code <= (_GEN_49 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_4_alu_op <= (_GEN_49 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_4_op1_sel <= (_GEN_49 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_4_op2_sel <= (_GEN_49 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_4_imm <= (_GEN_49 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_4_imm_sel <= (_GEN_49 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_4_is_w <= (_GEN_49 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_4_mem_cmd <= (_GEN_49 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_4_mem_size <= (_GEN_49 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_4_mem_signed <= (_GEN_49 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_4_br_type <= (_GEN_49 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_4_l_rd <= (_GEN_49 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_4_l_rs1 <= (_GEN_49 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_4_l_rs2 <= (_GEN_49 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_4_rf_wen <= (_GEN_49 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_4_use_rs1 <= alloc_uop_4_use_rs1;
			slot_uop_4_use_rs2 <= alloc_uop_4_use_rs2;
			slot_uop_4_p_rd <= (_GEN_49 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_4_p_rs1 <= (_GEN_49 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_4_p_rs2 <= (_GEN_49 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_4_prs1_ready <= alloc_uop_4_prs1_ready;
			slot_uop_4_prs2_ready <= alloc_uop_4_prs2_ready;
			slot_uop_4_stale_p_rd <= (_GEN_49 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_4_rob_idx <= (_GEN_49 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_4_exception <= (_GEN_49 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_4_pred_taken <= (_GEN_49 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_4_pred_target <= (_GEN_49 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_4 <= ~alloc_uop_4_use_rs1 | alloc_uop_4_prs1_ready;
			slot_rs2_ready_4 <= ~alloc_uop_4_use_rs2 | alloc_uop_4_prs2_ready;
		end
		else begin
			slot_rs1_ready_4 <= (~is_this_issued_4 & _GEN_7) | slot_rs1_ready_4;
			slot_rs2_ready_4 <= (~is_this_issued_4 & _GEN_8) | slot_rs2_ready_4;
		end
		if (is_this_alloc_5) begin : sv2v_autoblock_7
			reg _GEN_50;
			reg alloc_uop_5_use_rs1;
			reg alloc_uop_5_use_rs2;
			reg alloc_uop_5_prs1_ready;
			reg alloc_uop_5_prs2_ready;
			_GEN_50 = is_alloc_0_5 & io_enq_bits_0_valid;
			alloc_uop_5_use_rs1 = (_GEN_50 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_5_use_rs2 = (_GEN_50 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_5_prs1_ready = (_GEN_50 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_5_prs2_ready = (_GEN_50 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_5_valid <= (_GEN_50 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_5_pc <= (_GEN_50 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_5_inst <= (_GEN_50 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_5_fu_code <= (_GEN_50 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_5_alu_op <= (_GEN_50 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_5_op1_sel <= (_GEN_50 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_5_op2_sel <= (_GEN_50 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_5_imm <= (_GEN_50 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_5_imm_sel <= (_GEN_50 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_5_is_w <= (_GEN_50 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_5_mem_cmd <= (_GEN_50 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_5_mem_size <= (_GEN_50 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_5_mem_signed <= (_GEN_50 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_5_br_type <= (_GEN_50 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_5_l_rd <= (_GEN_50 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_5_l_rs1 <= (_GEN_50 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_5_l_rs2 <= (_GEN_50 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_5_rf_wen <= (_GEN_50 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_5_use_rs1 <= alloc_uop_5_use_rs1;
			slot_uop_5_use_rs2 <= alloc_uop_5_use_rs2;
			slot_uop_5_p_rd <= (_GEN_50 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_5_p_rs1 <= (_GEN_50 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_5_p_rs2 <= (_GEN_50 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_5_prs1_ready <= alloc_uop_5_prs1_ready;
			slot_uop_5_prs2_ready <= alloc_uop_5_prs2_ready;
			slot_uop_5_stale_p_rd <= (_GEN_50 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_5_rob_idx <= (_GEN_50 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_5_exception <= (_GEN_50 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_5_pred_taken <= (_GEN_50 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_5_pred_target <= (_GEN_50 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_5 <= ~alloc_uop_5_use_rs1 | alloc_uop_5_prs1_ready;
			slot_rs2_ready_5 <= ~alloc_uop_5_use_rs2 | alloc_uop_5_prs2_ready;
		end
		else begin
			slot_rs1_ready_5 <= (~is_this_issued_5 & _GEN_9) | slot_rs1_ready_5;
			slot_rs2_ready_5 <= (~is_this_issued_5 & _GEN_10) | slot_rs2_ready_5;
		end
		if (is_this_alloc_6) begin : sv2v_autoblock_8
			reg _GEN_51;
			reg alloc_uop_6_use_rs1;
			reg alloc_uop_6_use_rs2;
			reg alloc_uop_6_prs1_ready;
			reg alloc_uop_6_prs2_ready;
			_GEN_51 = is_alloc_0_6 & io_enq_bits_0_valid;
			alloc_uop_6_use_rs1 = (_GEN_51 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_6_use_rs2 = (_GEN_51 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_6_prs1_ready = (_GEN_51 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_6_prs2_ready = (_GEN_51 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_6_valid <= (_GEN_51 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_6_pc <= (_GEN_51 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_6_inst <= (_GEN_51 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_6_fu_code <= (_GEN_51 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_6_alu_op <= (_GEN_51 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_6_op1_sel <= (_GEN_51 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_6_op2_sel <= (_GEN_51 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_6_imm <= (_GEN_51 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_6_imm_sel <= (_GEN_51 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_6_is_w <= (_GEN_51 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_6_mem_cmd <= (_GEN_51 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_6_mem_size <= (_GEN_51 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_6_mem_signed <= (_GEN_51 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_6_br_type <= (_GEN_51 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_6_l_rd <= (_GEN_51 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_6_l_rs1 <= (_GEN_51 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_6_l_rs2 <= (_GEN_51 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_6_rf_wen <= (_GEN_51 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_6_use_rs1 <= alloc_uop_6_use_rs1;
			slot_uop_6_use_rs2 <= alloc_uop_6_use_rs2;
			slot_uop_6_p_rd <= (_GEN_51 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_6_p_rs1 <= (_GEN_51 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_6_p_rs2 <= (_GEN_51 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_6_prs1_ready <= alloc_uop_6_prs1_ready;
			slot_uop_6_prs2_ready <= alloc_uop_6_prs2_ready;
			slot_uop_6_stale_p_rd <= (_GEN_51 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_6_rob_idx <= (_GEN_51 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_6_exception <= (_GEN_51 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_6_pred_taken <= (_GEN_51 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_6_pred_target <= (_GEN_51 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_6 <= ~alloc_uop_6_use_rs1 | alloc_uop_6_prs1_ready;
			slot_rs2_ready_6 <= ~alloc_uop_6_use_rs2 | alloc_uop_6_prs2_ready;
		end
		else begin
			slot_rs1_ready_6 <= (~is_this_issued_6 & _GEN_11) | slot_rs1_ready_6;
			slot_rs2_ready_6 <= (~is_this_issued_6 & _GEN_12) | slot_rs2_ready_6;
		end
		if (is_this_alloc_7) begin : sv2v_autoblock_9
			reg _GEN_52;
			reg alloc_uop_7_use_rs1;
			reg alloc_uop_7_use_rs2;
			reg alloc_uop_7_prs1_ready;
			reg alloc_uop_7_prs2_ready;
			_GEN_52 = is_alloc_0_7 & io_enq_bits_0_valid;
			alloc_uop_7_use_rs1 = (_GEN_52 ? io_enq_bits_0_use_rs1 : io_enq_bits_1_use_rs1);
			alloc_uop_7_use_rs2 = (_GEN_52 ? io_enq_bits_0_use_rs2 : io_enq_bits_1_use_rs2);
			alloc_uop_7_prs1_ready = (_GEN_52 ? io_enq_bits_0_prs1_ready : io_enq_bits_1_prs1_ready);
			alloc_uop_7_prs2_ready = (_GEN_52 ? io_enq_bits_0_prs2_ready : io_enq_bits_1_prs2_ready);
			slot_uop_7_valid <= (_GEN_52 ? io_enq_bits_0_valid : io_enq_bits_1_valid);
			slot_uop_7_pc <= (_GEN_52 ? io_enq_bits_0_pc : io_enq_bits_1_pc);
			slot_uop_7_inst <= (_GEN_52 ? io_enq_bits_0_inst : io_enq_bits_1_inst);
			slot_uop_7_fu_code <= (_GEN_52 ? io_enq_bits_0_fu_code : io_enq_bits_1_fu_code);
			slot_uop_7_alu_op <= (_GEN_52 ? io_enq_bits_0_alu_op : io_enq_bits_1_alu_op);
			slot_uop_7_op1_sel <= (_GEN_52 ? io_enq_bits_0_op1_sel : io_enq_bits_1_op1_sel);
			slot_uop_7_op2_sel <= (_GEN_52 ? io_enq_bits_0_op2_sel : io_enq_bits_1_op2_sel);
			slot_uop_7_imm <= (_GEN_52 ? io_enq_bits_0_imm : io_enq_bits_1_imm);
			slot_uop_7_imm_sel <= (_GEN_52 ? io_enq_bits_0_imm_sel : io_enq_bits_1_imm_sel);
			slot_uop_7_is_w <= (_GEN_52 ? io_enq_bits_0_is_w : io_enq_bits_1_is_w);
			slot_uop_7_mem_cmd <= (_GEN_52 ? io_enq_bits_0_mem_cmd : io_enq_bits_1_mem_cmd);
			slot_uop_7_mem_size <= (_GEN_52 ? io_enq_bits_0_mem_size : io_enq_bits_1_mem_size);
			slot_uop_7_mem_signed <= (_GEN_52 ? io_enq_bits_0_mem_signed : io_enq_bits_1_mem_signed);
			slot_uop_7_br_type <= (_GEN_52 ? io_enq_bits_0_br_type : io_enq_bits_1_br_type);
			slot_uop_7_l_rd <= (_GEN_52 ? io_enq_bits_0_l_rd : io_enq_bits_1_l_rd);
			slot_uop_7_l_rs1 <= (_GEN_52 ? io_enq_bits_0_l_rs1 : io_enq_bits_1_l_rs1);
			slot_uop_7_l_rs2 <= (_GEN_52 ? io_enq_bits_0_l_rs2 : io_enq_bits_1_l_rs2);
			slot_uop_7_rf_wen <= (_GEN_52 ? io_enq_bits_0_rf_wen : io_enq_bits_1_rf_wen);
			slot_uop_7_use_rs1 <= alloc_uop_7_use_rs1;
			slot_uop_7_use_rs2 <= alloc_uop_7_use_rs2;
			slot_uop_7_p_rd <= (_GEN_52 ? io_enq_bits_0_p_rd : io_enq_bits_1_p_rd);
			slot_uop_7_p_rs1 <= (_GEN_52 ? io_enq_bits_0_p_rs1 : io_enq_bits_1_p_rs1);
			slot_uop_7_p_rs2 <= (_GEN_52 ? io_enq_bits_0_p_rs2 : io_enq_bits_1_p_rs2);
			slot_uop_7_prs1_ready <= alloc_uop_7_prs1_ready;
			slot_uop_7_prs2_ready <= alloc_uop_7_prs2_ready;
			slot_uop_7_stale_p_rd <= (_GEN_52 ? io_enq_bits_0_stale_p_rd : io_enq_bits_1_stale_p_rd);
			slot_uop_7_rob_idx <= (_GEN_52 ? io_enq_bits_0_rob_idx : io_enq_bits_1_rob_idx);
			slot_uop_7_exception <= (_GEN_52 ? io_enq_bits_0_exception : io_enq_bits_1_exception);
			slot_uop_7_pred_taken <= (_GEN_52 ? io_enq_bits_0_pred_taken : io_enq_bits_1_pred_taken);
			slot_uop_7_pred_target <= (_GEN_52 ? io_enq_bits_0_pred_target : io_enq_bits_1_pred_target);
			slot_rs1_ready_7 <= ~alloc_uop_7_use_rs1 | alloc_uop_7_prs1_ready;
			slot_rs2_ready_7 <= ~alloc_uop_7_use_rs2 | alloc_uop_7_prs2_ready;
		end
		else begin
			slot_rs1_ready_7 <= (~is_this_issued_7 & _GEN_13) | slot_rs1_ready_7;
			slot_rs2_ready_7 <= (~is_this_issued_7 & _GEN_14) | slot_rs2_ready_7;
		end
	end
	assign io_enq_ready = io_enq_ready_0;
	assign io_iss_alu_valid = |_can_iss_alu_T;
	assign io_iss_alu_bits_valid = _GEN_15[sel_alu_idx];
	assign io_iss_alu_bits_pc = _GEN_16[sel_alu_idx * 64+:64];
	assign io_iss_alu_bits_inst = _GEN_17[sel_alu_idx * 32+:32];
	assign io_iss_alu_bits_fu_code = _GEN_18[sel_alu_idx * 6+:6];
	assign io_iss_alu_bits_alu_op = _GEN_19[sel_alu_idx * 10+:10];
	assign io_iss_alu_bits_op1_sel = _GEN_20[sel_alu_idx * 2+:2];
	assign io_iss_alu_bits_op2_sel = _GEN_21[sel_alu_idx * 3+:3];
	assign io_iss_alu_bits_imm = _GEN_22[sel_alu_idx * 64+:64];
	assign io_iss_alu_bits_imm_sel = _GEN_23[sel_alu_idx * 3+:3];
	assign io_iss_alu_bits_is_w = _GEN_24[sel_alu_idx];
	assign io_iss_alu_bits_mem_cmd = _GEN_25[sel_alu_idx * 3+:3];
	assign io_iss_alu_bits_mem_size = _GEN_26[sel_alu_idx * 2+:2];
	assign io_iss_alu_bits_mem_signed = _GEN_27[sel_alu_idx];
	assign io_iss_alu_bits_br_type = _GEN_28[sel_alu_idx * 4+:4];
	assign io_iss_alu_bits_l_rd = _GEN_29[sel_alu_idx * 5+:5];
	assign io_iss_alu_bits_l_rs1 = _GEN_30[sel_alu_idx * 5+:5];
	assign io_iss_alu_bits_l_rs2 = _GEN_31[sel_alu_idx * 5+:5];
	assign io_iss_alu_bits_rf_wen = _GEN_32[sel_alu_idx];
	assign io_iss_alu_bits_use_rs1 = _GEN_33[sel_alu_idx];
	assign io_iss_alu_bits_use_rs2 = _GEN_34[sel_alu_idx];
	assign io_iss_alu_bits_p_rd = _GEN_35[sel_alu_idx * 6+:6];
	assign io_iss_alu_bits_p_rs1 = _GEN_36[sel_alu_idx * 6+:6];
	assign io_iss_alu_bits_p_rs2 = _GEN_37[sel_alu_idx * 6+:6];
	assign io_iss_alu_bits_prs1_ready = _GEN_38[sel_alu_idx];
	assign io_iss_alu_bits_prs2_ready = _GEN_39[sel_alu_idx];
	assign io_iss_alu_bits_stale_p_rd = _GEN_40[sel_alu_idx * 6+:6];
	assign io_iss_alu_bits_rob_idx = _GEN_41[sel_alu_idx * 4+:4];
	assign io_iss_alu_bits_exception = _GEN_42[sel_alu_idx];
	assign io_iss_alu_bits_pred_taken = _GEN_43[sel_alu_idx];
	assign io_iss_alu_bits_pred_target = _GEN_44[sel_alu_idx * 64+:64];
	assign io_iss_lsu_valid = |_can_iss_lsu_T;
	assign io_iss_lsu_bits_valid = _GEN_15[sel_lsu_idx];
	assign io_iss_lsu_bits_pc = _GEN_16[sel_lsu_idx * 64+:64];
	assign io_iss_lsu_bits_inst = _GEN_17[sel_lsu_idx * 32+:32];
	assign io_iss_lsu_bits_fu_code = _GEN_18[sel_lsu_idx * 6+:6];
	assign io_iss_lsu_bits_alu_op = _GEN_19[sel_lsu_idx * 10+:10];
	assign io_iss_lsu_bits_op1_sel = _GEN_20[sel_lsu_idx * 2+:2];
	assign io_iss_lsu_bits_op2_sel = _GEN_21[sel_lsu_idx * 3+:3];
	assign io_iss_lsu_bits_imm = _GEN_22[sel_lsu_idx * 64+:64];
	assign io_iss_lsu_bits_imm_sel = _GEN_23[sel_lsu_idx * 3+:3];
	assign io_iss_lsu_bits_is_w = _GEN_24[sel_lsu_idx];
	assign io_iss_lsu_bits_mem_cmd = _GEN_25[sel_lsu_idx * 3+:3];
	assign io_iss_lsu_bits_mem_size = _GEN_26[sel_lsu_idx * 2+:2];
	assign io_iss_lsu_bits_mem_signed = _GEN_27[sel_lsu_idx];
	assign io_iss_lsu_bits_br_type = _GEN_28[sel_lsu_idx * 4+:4];
	assign io_iss_lsu_bits_l_rd = _GEN_29[sel_lsu_idx * 5+:5];
	assign io_iss_lsu_bits_l_rs1 = _GEN_30[sel_lsu_idx * 5+:5];
	assign io_iss_lsu_bits_l_rs2 = _GEN_31[sel_lsu_idx * 5+:5];
	assign io_iss_lsu_bits_rf_wen = _GEN_32[sel_lsu_idx];
	assign io_iss_lsu_bits_use_rs1 = _GEN_33[sel_lsu_idx];
	assign io_iss_lsu_bits_use_rs2 = _GEN_34[sel_lsu_idx];
	assign io_iss_lsu_bits_p_rd = _GEN_35[sel_lsu_idx * 6+:6];
	assign io_iss_lsu_bits_p_rs1 = _GEN_36[sel_lsu_idx * 6+:6];
	assign io_iss_lsu_bits_p_rs2 = _GEN_37[sel_lsu_idx * 6+:6];
	assign io_iss_lsu_bits_prs1_ready = _GEN_38[sel_lsu_idx];
	assign io_iss_lsu_bits_prs2_ready = _GEN_39[sel_lsu_idx];
	assign io_iss_lsu_bits_stale_p_rd = _GEN_40[sel_lsu_idx * 6+:6];
	assign io_iss_lsu_bits_rob_idx = _GEN_41[sel_lsu_idx * 4+:4];
	assign io_iss_lsu_bits_exception = _GEN_42[sel_lsu_idx];
	assign io_iss_lsu_bits_pred_taken = _GEN_43[sel_lsu_idx];
	assign io_iss_lsu_bits_pred_target = _GEN_44[sel_lsu_idx * 64+:64];
endmodule
module ram_2x358 (
	R0_addr,
	R0_en,
	R0_clk,
	R0_data,
	W0_addr,
	W0_en,
	W0_clk,
	W0_data
);
	input R0_addr;
	input R0_en;
	input R0_clk;
	output wire [357:0] R0_data;
	input W0_addr;
	input W0_en;
	input W0_clk;
	input [357:0] W0_data;
	reg [357:0] Memory [0:1];
	always @(posedge W0_clk)
		if (W0_en & 1'h1)
			Memory[W0_addr] <= W0_data;
	assign R0_data = (R0_en ? Memory[R0_addr] : 358'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
endmodule
module Queue2_FuncUnitReq (
	clock,
	reset,
	io_enq_ready,
	io_enq_valid,
	io_enq_bits_uop_valid,
	io_enq_bits_uop_pc,
	io_enq_bits_uop_inst,
	io_enq_bits_uop_fu_code,
	io_enq_bits_uop_alu_op,
	io_enq_bits_uop_op1_sel,
	io_enq_bits_uop_op2_sel,
	io_enq_bits_uop_imm,
	io_enq_bits_uop_imm_sel,
	io_enq_bits_uop_is_w,
	io_enq_bits_uop_mem_cmd,
	io_enq_bits_uop_mem_size,
	io_enq_bits_uop_mem_signed,
	io_enq_bits_uop_br_type,
	io_enq_bits_uop_l_rd,
	io_enq_bits_uop_l_rs1,
	io_enq_bits_uop_l_rs2,
	io_enq_bits_uop_rf_wen,
	io_enq_bits_uop_use_rs1,
	io_enq_bits_uop_use_rs2,
	io_enq_bits_uop_p_rd,
	io_enq_bits_uop_p_rs1,
	io_enq_bits_uop_p_rs2,
	io_enq_bits_uop_prs1_ready,
	io_enq_bits_uop_prs2_ready,
	io_enq_bits_uop_stale_p_rd,
	io_enq_bits_uop_rob_idx,
	io_enq_bits_uop_exception,
	io_enq_bits_uop_pred_taken,
	io_enq_bits_uop_pred_target,
	io_enq_bits_rs1_data,
	io_enq_bits_rs2_data,
	io_deq_ready,
	io_deq_valid,
	io_deq_bits_uop_pc,
	io_deq_bits_uop_alu_op,
	io_deq_bits_uop_op1_sel,
	io_deq_bits_uop_op2_sel,
	io_deq_bits_uop_imm,
	io_deq_bits_uop_is_w,
	io_deq_bits_uop_mem_cmd,
	io_deq_bits_uop_mem_size,
	io_deq_bits_uop_mem_signed,
	io_deq_bits_uop_br_type,
	io_deq_bits_uop_p_rd,
	io_deq_bits_uop_rob_idx,
	io_deq_bits_uop_exception,
	io_deq_bits_uop_pred_taken,
	io_deq_bits_uop_pred_target,
	io_deq_bits_rs1_data,
	io_deq_bits_rs2_data
);
	input clock;
	input reset;
	output wire io_enq_ready;
	input io_enq_valid;
	input io_enq_bits_uop_valid;
	input [63:0] io_enq_bits_uop_pc;
	input [31:0] io_enq_bits_uop_inst;
	input [5:0] io_enq_bits_uop_fu_code;
	input [9:0] io_enq_bits_uop_alu_op;
	input [1:0] io_enq_bits_uop_op1_sel;
	input [2:0] io_enq_bits_uop_op2_sel;
	input [63:0] io_enq_bits_uop_imm;
	input [2:0] io_enq_bits_uop_imm_sel;
	input io_enq_bits_uop_is_w;
	input [2:0] io_enq_bits_uop_mem_cmd;
	input [1:0] io_enq_bits_uop_mem_size;
	input io_enq_bits_uop_mem_signed;
	input [3:0] io_enq_bits_uop_br_type;
	input [4:0] io_enq_bits_uop_l_rd;
	input [4:0] io_enq_bits_uop_l_rs1;
	input [4:0] io_enq_bits_uop_l_rs2;
	input io_enq_bits_uop_rf_wen;
	input io_enq_bits_uop_use_rs1;
	input io_enq_bits_uop_use_rs2;
	input [5:0] io_enq_bits_uop_p_rd;
	input [5:0] io_enq_bits_uop_p_rs1;
	input [5:0] io_enq_bits_uop_p_rs2;
	input io_enq_bits_uop_prs1_ready;
	input io_enq_bits_uop_prs2_ready;
	input [5:0] io_enq_bits_uop_stale_p_rd;
	input [3:0] io_enq_bits_uop_rob_idx;
	input io_enq_bits_uop_exception;
	input io_enq_bits_uop_pred_taken;
	input [63:0] io_enq_bits_uop_pred_target;
	input [63:0] io_enq_bits_rs1_data;
	input [63:0] io_enq_bits_rs2_data;
	input io_deq_ready;
	output wire io_deq_valid;
	output wire [63:0] io_deq_bits_uop_pc;
	output wire [9:0] io_deq_bits_uop_alu_op;
	output wire [1:0] io_deq_bits_uop_op1_sel;
	output wire [2:0] io_deq_bits_uop_op2_sel;
	output wire [63:0] io_deq_bits_uop_imm;
	output wire io_deq_bits_uop_is_w;
	output wire [2:0] io_deq_bits_uop_mem_cmd;
	output wire [1:0] io_deq_bits_uop_mem_size;
	output wire io_deq_bits_uop_mem_signed;
	output wire [3:0] io_deq_bits_uop_br_type;
	output wire [5:0] io_deq_bits_uop_p_rd;
	output wire [3:0] io_deq_bits_uop_rob_idx;
	output wire io_deq_bits_uop_exception;
	output wire io_deq_bits_uop_pred_taken;
	output wire [63:0] io_deq_bits_uop_pred_target;
	output wire [63:0] io_deq_bits_rs1_data;
	output wire [63:0] io_deq_bits_rs2_data;
	wire [357:0] _ram_ext_R0_data;
	reg wrap;
	reg wrap_1;
	reg maybe_full;
	wire ptr_match = wrap == wrap_1;
	wire empty = ptr_match & ~maybe_full;
	wire full = ptr_match & maybe_full;
	wire do_enq = ~full & io_enq_valid;
	always @(posedge clock)
		if (reset) begin
			wrap <= 1'h0;
			wrap_1 <= 1'h0;
			maybe_full <= 1'h0;
		end
		else begin : sv2v_autoblock_1
			reg do_deq;
			do_deq = io_deq_ready & ~empty;
			if (do_enq)
				wrap <= wrap - 1'h1;
			if (do_deq)
				wrap_1 <= wrap_1 - 1'h1;
			if (~(do_enq == do_deq))
				maybe_full <= do_enq;
		end
	ram_2x358 ram_ext(
		.R0_addr(wrap_1),
		.R0_en(1'h1),
		.R0_clk(clock),
		.R0_data(_ram_ext_R0_data),
		.W0_addr(wrap),
		.W0_en(do_enq),
		.W0_clk(clock),
		.W0_data({io_enq_bits_rs2_data, io_enq_bits_rs1_data, io_enq_bits_uop_pred_target, io_enq_bits_uop_pred_taken, io_enq_bits_uop_exception, io_enq_bits_uop_rob_idx, io_enq_bits_uop_p_rd, io_enq_bits_uop_br_type, io_enq_bits_uop_mem_signed, io_enq_bits_uop_mem_size, io_enq_bits_uop_mem_cmd, io_enq_bits_uop_is_w, io_enq_bits_uop_imm, io_enq_bits_uop_op2_sel, io_enq_bits_uop_op1_sel, io_enq_bits_uop_alu_op, io_enq_bits_uop_pc})
	);
	assign io_enq_ready = ~full;
	assign io_deq_valid = ~empty;
	assign io_deq_bits_uop_pc = _ram_ext_R0_data[63:0];
	assign io_deq_bits_uop_alu_op = _ram_ext_R0_data[73:64];
	assign io_deq_bits_uop_op1_sel = _ram_ext_R0_data[75:74];
	assign io_deq_bits_uop_op2_sel = _ram_ext_R0_data[78:76];
	assign io_deq_bits_uop_imm = _ram_ext_R0_data[142:79];
	assign io_deq_bits_uop_is_w = _ram_ext_R0_data[143];
	assign io_deq_bits_uop_mem_cmd = _ram_ext_R0_data[146:144];
	assign io_deq_bits_uop_mem_size = _ram_ext_R0_data[148:147];
	assign io_deq_bits_uop_mem_signed = _ram_ext_R0_data[149];
	assign io_deq_bits_uop_br_type = _ram_ext_R0_data[153:150];
	assign io_deq_bits_uop_p_rd = _ram_ext_R0_data[159:154];
	assign io_deq_bits_uop_rob_idx = _ram_ext_R0_data[163:160];
	assign io_deq_bits_uop_exception = _ram_ext_R0_data[164];
	assign io_deq_bits_uop_pred_taken = _ram_ext_R0_data[165];
	assign io_deq_bits_uop_pred_target = _ram_ext_R0_data[229:166];
	assign io_deq_bits_rs1_data = _ram_ext_R0_data[293:230];
	assign io_deq_bits_rs2_data = _ram_ext_R0_data[357:294];
endmodule
module RegRead (
	clock,
	reset,
	io_iss_alu_ready,
	io_iss_alu_valid,
	io_iss_alu_bits_valid,
	io_iss_alu_bits_pc,
	io_iss_alu_bits_inst,
	io_iss_alu_bits_fu_code,
	io_iss_alu_bits_alu_op,
	io_iss_alu_bits_op1_sel,
	io_iss_alu_bits_op2_sel,
	io_iss_alu_bits_imm,
	io_iss_alu_bits_imm_sel,
	io_iss_alu_bits_is_w,
	io_iss_alu_bits_mem_cmd,
	io_iss_alu_bits_mem_size,
	io_iss_alu_bits_mem_signed,
	io_iss_alu_bits_br_type,
	io_iss_alu_bits_l_rd,
	io_iss_alu_bits_l_rs1,
	io_iss_alu_bits_l_rs2,
	io_iss_alu_bits_rf_wen,
	io_iss_alu_bits_use_rs1,
	io_iss_alu_bits_use_rs2,
	io_iss_alu_bits_p_rd,
	io_iss_alu_bits_p_rs1,
	io_iss_alu_bits_p_rs2,
	io_iss_alu_bits_prs1_ready,
	io_iss_alu_bits_prs2_ready,
	io_iss_alu_bits_stale_p_rd,
	io_iss_alu_bits_rob_idx,
	io_iss_alu_bits_exception,
	io_iss_alu_bits_pred_taken,
	io_iss_alu_bits_pred_target,
	io_iss_lsu_ready,
	io_iss_lsu_valid,
	io_iss_lsu_bits_valid,
	io_iss_lsu_bits_pc,
	io_iss_lsu_bits_inst,
	io_iss_lsu_bits_fu_code,
	io_iss_lsu_bits_alu_op,
	io_iss_lsu_bits_op1_sel,
	io_iss_lsu_bits_op2_sel,
	io_iss_lsu_bits_imm,
	io_iss_lsu_bits_imm_sel,
	io_iss_lsu_bits_is_w,
	io_iss_lsu_bits_mem_cmd,
	io_iss_lsu_bits_mem_size,
	io_iss_lsu_bits_mem_signed,
	io_iss_lsu_bits_br_type,
	io_iss_lsu_bits_l_rd,
	io_iss_lsu_bits_l_rs1,
	io_iss_lsu_bits_l_rs2,
	io_iss_lsu_bits_rf_wen,
	io_iss_lsu_bits_use_rs1,
	io_iss_lsu_bits_use_rs2,
	io_iss_lsu_bits_p_rd,
	io_iss_lsu_bits_p_rs1,
	io_iss_lsu_bits_p_rs2,
	io_iss_lsu_bits_prs1_ready,
	io_iss_lsu_bits_prs2_ready,
	io_iss_lsu_bits_stale_p_rd,
	io_iss_lsu_bits_rob_idx,
	io_iss_lsu_bits_exception,
	io_iss_lsu_bits_pred_taken,
	io_iss_lsu_bits_pred_target,
	io_exe_alu_valid,
	io_exe_alu_bits_uop_pc,
	io_exe_alu_bits_uop_alu_op,
	io_exe_alu_bits_uop_op1_sel,
	io_exe_alu_bits_uop_op2_sel,
	io_exe_alu_bits_uop_imm,
	io_exe_alu_bits_uop_is_w,
	io_exe_alu_bits_uop_br_type,
	io_exe_alu_bits_uop_p_rd,
	io_exe_alu_bits_uop_rob_idx,
	io_exe_alu_bits_uop_exception,
	io_exe_alu_bits_uop_pred_taken,
	io_exe_alu_bits_uop_pred_target,
	io_exe_alu_bits_rs1_data,
	io_exe_alu_bits_rs2_data,
	io_exe_lsu_ready,
	io_exe_lsu_valid,
	io_exe_lsu_bits_uop_imm,
	io_exe_lsu_bits_uop_mem_cmd,
	io_exe_lsu_bits_uop_mem_size,
	io_exe_lsu_bits_uop_mem_signed,
	io_exe_lsu_bits_uop_p_rd,
	io_exe_lsu_bits_uop_rob_idx,
	io_exe_lsu_bits_uop_exception,
	io_exe_lsu_bits_rs1_data,
	io_exe_lsu_bits_rs2_data,
	io_prf_alu_req_rs1,
	io_prf_alu_req_rs2,
	io_prf_alu_resp_rs1,
	io_prf_alu_resp_rs2,
	io_prf_lsu_req_rs1,
	io_prf_lsu_req_rs2,
	io_prf_lsu_resp_rs1,
	io_prf_lsu_resp_rs2,
	io_cdb_0_valid,
	io_cdb_0_bits_p_rd,
	io_cdb_0_bits_data,
	io_cdb_1_valid,
	io_cdb_1_bits_p_rd,
	io_cdb_1_bits_data
);
	input clock;
	input reset;
	output wire io_iss_alu_ready;
	input io_iss_alu_valid;
	input io_iss_alu_bits_valid;
	input [63:0] io_iss_alu_bits_pc;
	input [31:0] io_iss_alu_bits_inst;
	input [5:0] io_iss_alu_bits_fu_code;
	input [9:0] io_iss_alu_bits_alu_op;
	input [1:0] io_iss_alu_bits_op1_sel;
	input [2:0] io_iss_alu_bits_op2_sel;
	input [63:0] io_iss_alu_bits_imm;
	input [2:0] io_iss_alu_bits_imm_sel;
	input io_iss_alu_bits_is_w;
	input [2:0] io_iss_alu_bits_mem_cmd;
	input [1:0] io_iss_alu_bits_mem_size;
	input io_iss_alu_bits_mem_signed;
	input [3:0] io_iss_alu_bits_br_type;
	input [4:0] io_iss_alu_bits_l_rd;
	input [4:0] io_iss_alu_bits_l_rs1;
	input [4:0] io_iss_alu_bits_l_rs2;
	input io_iss_alu_bits_rf_wen;
	input io_iss_alu_bits_use_rs1;
	input io_iss_alu_bits_use_rs2;
	input [5:0] io_iss_alu_bits_p_rd;
	input [5:0] io_iss_alu_bits_p_rs1;
	input [5:0] io_iss_alu_bits_p_rs2;
	input io_iss_alu_bits_prs1_ready;
	input io_iss_alu_bits_prs2_ready;
	input [5:0] io_iss_alu_bits_stale_p_rd;
	input [3:0] io_iss_alu_bits_rob_idx;
	input io_iss_alu_bits_exception;
	input io_iss_alu_bits_pred_taken;
	input [63:0] io_iss_alu_bits_pred_target;
	output wire io_iss_lsu_ready;
	input io_iss_lsu_valid;
	input io_iss_lsu_bits_valid;
	input [63:0] io_iss_lsu_bits_pc;
	input [31:0] io_iss_lsu_bits_inst;
	input [5:0] io_iss_lsu_bits_fu_code;
	input [9:0] io_iss_lsu_bits_alu_op;
	input [1:0] io_iss_lsu_bits_op1_sel;
	input [2:0] io_iss_lsu_bits_op2_sel;
	input [63:0] io_iss_lsu_bits_imm;
	input [2:0] io_iss_lsu_bits_imm_sel;
	input io_iss_lsu_bits_is_w;
	input [2:0] io_iss_lsu_bits_mem_cmd;
	input [1:0] io_iss_lsu_bits_mem_size;
	input io_iss_lsu_bits_mem_signed;
	input [3:0] io_iss_lsu_bits_br_type;
	input [4:0] io_iss_lsu_bits_l_rd;
	input [4:0] io_iss_lsu_bits_l_rs1;
	input [4:0] io_iss_lsu_bits_l_rs2;
	input io_iss_lsu_bits_rf_wen;
	input io_iss_lsu_bits_use_rs1;
	input io_iss_lsu_bits_use_rs2;
	input [5:0] io_iss_lsu_bits_p_rd;
	input [5:0] io_iss_lsu_bits_p_rs1;
	input [5:0] io_iss_lsu_bits_p_rs2;
	input io_iss_lsu_bits_prs1_ready;
	input io_iss_lsu_bits_prs2_ready;
	input [5:0] io_iss_lsu_bits_stale_p_rd;
	input [3:0] io_iss_lsu_bits_rob_idx;
	input io_iss_lsu_bits_exception;
	input io_iss_lsu_bits_pred_taken;
	input [63:0] io_iss_lsu_bits_pred_target;
	output wire io_exe_alu_valid;
	output wire [63:0] io_exe_alu_bits_uop_pc;
	output wire [9:0] io_exe_alu_bits_uop_alu_op;
	output wire [1:0] io_exe_alu_bits_uop_op1_sel;
	output wire [2:0] io_exe_alu_bits_uop_op2_sel;
	output wire [63:0] io_exe_alu_bits_uop_imm;
	output wire io_exe_alu_bits_uop_is_w;
	output wire [3:0] io_exe_alu_bits_uop_br_type;
	output wire [5:0] io_exe_alu_bits_uop_p_rd;
	output wire [3:0] io_exe_alu_bits_uop_rob_idx;
	output wire io_exe_alu_bits_uop_exception;
	output wire io_exe_alu_bits_uop_pred_taken;
	output wire [63:0] io_exe_alu_bits_uop_pred_target;
	output wire [63:0] io_exe_alu_bits_rs1_data;
	output wire [63:0] io_exe_alu_bits_rs2_data;
	input io_exe_lsu_ready;
	output wire io_exe_lsu_valid;
	output wire [63:0] io_exe_lsu_bits_uop_imm;
	output wire [2:0] io_exe_lsu_bits_uop_mem_cmd;
	output wire [1:0] io_exe_lsu_bits_uop_mem_size;
	output wire io_exe_lsu_bits_uop_mem_signed;
	output wire [5:0] io_exe_lsu_bits_uop_p_rd;
	output wire [3:0] io_exe_lsu_bits_uop_rob_idx;
	output wire io_exe_lsu_bits_uop_exception;
	output wire [63:0] io_exe_lsu_bits_rs1_data;
	output wire [63:0] io_exe_lsu_bits_rs2_data;
	output wire [5:0] io_prf_alu_req_rs1;
	output wire [5:0] io_prf_alu_req_rs2;
	input [63:0] io_prf_alu_resp_rs1;
	input [63:0] io_prf_alu_resp_rs2;
	output wire [5:0] io_prf_lsu_req_rs1;
	output wire [5:0] io_prf_lsu_req_rs2;
	input [63:0] io_prf_lsu_resp_rs1;
	input [63:0] io_prf_lsu_resp_rs2;
	input io_cdb_0_valid;
	input [5:0] io_cdb_0_bits_p_rd;
	input [63:0] io_cdb_0_bits_data;
	input io_cdb_1_valid;
	input [5:0] io_cdb_1_bits_p_rd;
	input [63:0] io_cdb_1_bits_data;
	Queue2_FuncUnitReq alu_pipe_reg(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(io_iss_alu_ready),
		.io_enq_valid(io_iss_alu_valid),
		.io_enq_bits_uop_valid(io_iss_alu_bits_valid),
		.io_enq_bits_uop_pc(io_iss_alu_bits_pc),
		.io_enq_bits_uop_inst(io_iss_alu_bits_inst),
		.io_enq_bits_uop_fu_code(io_iss_alu_bits_fu_code),
		.io_enq_bits_uop_alu_op(io_iss_alu_bits_alu_op),
		.io_enq_bits_uop_op1_sel(io_iss_alu_bits_op1_sel),
		.io_enq_bits_uop_op2_sel(io_iss_alu_bits_op2_sel),
		.io_enq_bits_uop_imm(io_iss_alu_bits_imm),
		.io_enq_bits_uop_imm_sel(io_iss_alu_bits_imm_sel),
		.io_enq_bits_uop_is_w(io_iss_alu_bits_is_w),
		.io_enq_bits_uop_mem_cmd(io_iss_alu_bits_mem_cmd),
		.io_enq_bits_uop_mem_size(io_iss_alu_bits_mem_size),
		.io_enq_bits_uop_mem_signed(io_iss_alu_bits_mem_signed),
		.io_enq_bits_uop_br_type(io_iss_alu_bits_br_type),
		.io_enq_bits_uop_l_rd(io_iss_alu_bits_l_rd),
		.io_enq_bits_uop_l_rs1(io_iss_alu_bits_l_rs1),
		.io_enq_bits_uop_l_rs2(io_iss_alu_bits_l_rs2),
		.io_enq_bits_uop_rf_wen(io_iss_alu_bits_rf_wen),
		.io_enq_bits_uop_use_rs1(io_iss_alu_bits_use_rs1),
		.io_enq_bits_uop_use_rs2(io_iss_alu_bits_use_rs2),
		.io_enq_bits_uop_p_rd(io_iss_alu_bits_p_rd),
		.io_enq_bits_uop_p_rs1(io_iss_alu_bits_p_rs1),
		.io_enq_bits_uop_p_rs2(io_iss_alu_bits_p_rs2),
		.io_enq_bits_uop_prs1_ready(io_iss_alu_bits_prs1_ready),
		.io_enq_bits_uop_prs2_ready(io_iss_alu_bits_prs2_ready),
		.io_enq_bits_uop_stale_p_rd(io_iss_alu_bits_stale_p_rd),
		.io_enq_bits_uop_rob_idx(io_iss_alu_bits_rob_idx),
		.io_enq_bits_uop_exception(io_iss_alu_bits_exception),
		.io_enq_bits_uop_pred_taken(io_iss_alu_bits_pred_taken),
		.io_enq_bits_uop_pred_target(io_iss_alu_bits_pred_target),
		.io_enq_bits_rs1_data(((io_cdb_0_valid & (io_cdb_0_bits_p_rd == io_iss_alu_bits_p_rs1)) & |io_iss_alu_bits_p_rs1 ? io_cdb_0_bits_data : ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == io_iss_alu_bits_p_rs1)) & |io_iss_alu_bits_p_rs1 ? io_cdb_1_bits_data : io_prf_alu_resp_rs1))),
		.io_enq_bits_rs2_data(((io_cdb_0_valid & (io_cdb_0_bits_p_rd == io_iss_alu_bits_p_rs2)) & |io_iss_alu_bits_p_rs2 ? io_cdb_0_bits_data : ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == io_iss_alu_bits_p_rs2)) & |io_iss_alu_bits_p_rs2 ? io_cdb_1_bits_data : io_prf_alu_resp_rs2))),
		.io_deq_ready(1'h1),
		.io_deq_valid(io_exe_alu_valid),
		.io_deq_bits_uop_pc(io_exe_alu_bits_uop_pc),
		.io_deq_bits_uop_alu_op(io_exe_alu_bits_uop_alu_op),
		.io_deq_bits_uop_op1_sel(io_exe_alu_bits_uop_op1_sel),
		.io_deq_bits_uop_op2_sel(io_exe_alu_bits_uop_op2_sel),
		.io_deq_bits_uop_imm(io_exe_alu_bits_uop_imm),
		.io_deq_bits_uop_is_w(io_exe_alu_bits_uop_is_w),
		.io_deq_bits_uop_mem_cmd(),
		.io_deq_bits_uop_mem_size(),
		.io_deq_bits_uop_mem_signed(),
		.io_deq_bits_uop_br_type(io_exe_alu_bits_uop_br_type),
		.io_deq_bits_uop_p_rd(io_exe_alu_bits_uop_p_rd),
		.io_deq_bits_uop_rob_idx(io_exe_alu_bits_uop_rob_idx),
		.io_deq_bits_uop_exception(io_exe_alu_bits_uop_exception),
		.io_deq_bits_uop_pred_taken(io_exe_alu_bits_uop_pred_taken),
		.io_deq_bits_uop_pred_target(io_exe_alu_bits_uop_pred_target),
		.io_deq_bits_rs1_data(io_exe_alu_bits_rs1_data),
		.io_deq_bits_rs2_data(io_exe_alu_bits_rs2_data)
	);
	Queue2_FuncUnitReq lsu_pipe_reg(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(io_iss_lsu_ready),
		.io_enq_valid(io_iss_lsu_valid),
		.io_enq_bits_uop_valid(io_iss_lsu_bits_valid),
		.io_enq_bits_uop_pc(io_iss_lsu_bits_pc),
		.io_enq_bits_uop_inst(io_iss_lsu_bits_inst),
		.io_enq_bits_uop_fu_code(io_iss_lsu_bits_fu_code),
		.io_enq_bits_uop_alu_op(io_iss_lsu_bits_alu_op),
		.io_enq_bits_uop_op1_sel(io_iss_lsu_bits_op1_sel),
		.io_enq_bits_uop_op2_sel(io_iss_lsu_bits_op2_sel),
		.io_enq_bits_uop_imm(io_iss_lsu_bits_imm),
		.io_enq_bits_uop_imm_sel(io_iss_lsu_bits_imm_sel),
		.io_enq_bits_uop_is_w(io_iss_lsu_bits_is_w),
		.io_enq_bits_uop_mem_cmd(io_iss_lsu_bits_mem_cmd),
		.io_enq_bits_uop_mem_size(io_iss_lsu_bits_mem_size),
		.io_enq_bits_uop_mem_signed(io_iss_lsu_bits_mem_signed),
		.io_enq_bits_uop_br_type(io_iss_lsu_bits_br_type),
		.io_enq_bits_uop_l_rd(io_iss_lsu_bits_l_rd),
		.io_enq_bits_uop_l_rs1(io_iss_lsu_bits_l_rs1),
		.io_enq_bits_uop_l_rs2(io_iss_lsu_bits_l_rs2),
		.io_enq_bits_uop_rf_wen(io_iss_lsu_bits_rf_wen),
		.io_enq_bits_uop_use_rs1(io_iss_lsu_bits_use_rs1),
		.io_enq_bits_uop_use_rs2(io_iss_lsu_bits_use_rs2),
		.io_enq_bits_uop_p_rd(io_iss_lsu_bits_p_rd),
		.io_enq_bits_uop_p_rs1(io_iss_lsu_bits_p_rs1),
		.io_enq_bits_uop_p_rs2(io_iss_lsu_bits_p_rs2),
		.io_enq_bits_uop_prs1_ready(io_iss_lsu_bits_prs1_ready),
		.io_enq_bits_uop_prs2_ready(io_iss_lsu_bits_prs2_ready),
		.io_enq_bits_uop_stale_p_rd(io_iss_lsu_bits_stale_p_rd),
		.io_enq_bits_uop_rob_idx(io_iss_lsu_bits_rob_idx),
		.io_enq_bits_uop_exception(io_iss_lsu_bits_exception),
		.io_enq_bits_uop_pred_taken(io_iss_lsu_bits_pred_taken),
		.io_enq_bits_uop_pred_target(io_iss_lsu_bits_pred_target),
		.io_enq_bits_rs1_data(((io_cdb_0_valid & (io_cdb_0_bits_p_rd == io_iss_lsu_bits_p_rs1)) & |io_iss_lsu_bits_p_rs1 ? io_cdb_0_bits_data : ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == io_iss_lsu_bits_p_rs1)) & |io_iss_lsu_bits_p_rs1 ? io_cdb_1_bits_data : io_prf_lsu_resp_rs1))),
		.io_enq_bits_rs2_data(((io_cdb_0_valid & (io_cdb_0_bits_p_rd == io_iss_lsu_bits_p_rs2)) & |io_iss_lsu_bits_p_rs2 ? io_cdb_0_bits_data : ((io_cdb_1_valid & (io_cdb_1_bits_p_rd == io_iss_lsu_bits_p_rs2)) & |io_iss_lsu_bits_p_rs2 ? io_cdb_1_bits_data : io_prf_lsu_resp_rs2))),
		.io_deq_ready(io_exe_lsu_ready),
		.io_deq_valid(io_exe_lsu_valid),
		.io_deq_bits_uop_pc(),
		.io_deq_bits_uop_alu_op(),
		.io_deq_bits_uop_op1_sel(),
		.io_deq_bits_uop_op2_sel(),
		.io_deq_bits_uop_imm(io_exe_lsu_bits_uop_imm),
		.io_deq_bits_uop_is_w(),
		.io_deq_bits_uop_mem_cmd(io_exe_lsu_bits_uop_mem_cmd),
		.io_deq_bits_uop_mem_size(io_exe_lsu_bits_uop_mem_size),
		.io_deq_bits_uop_mem_signed(io_exe_lsu_bits_uop_mem_signed),
		.io_deq_bits_uop_br_type(),
		.io_deq_bits_uop_p_rd(io_exe_lsu_bits_uop_p_rd),
		.io_deq_bits_uop_rob_idx(io_exe_lsu_bits_uop_rob_idx),
		.io_deq_bits_uop_exception(io_exe_lsu_bits_uop_exception),
		.io_deq_bits_uop_pred_taken(),
		.io_deq_bits_uop_pred_target(),
		.io_deq_bits_rs1_data(io_exe_lsu_bits_rs1_data),
		.io_deq_bits_rs2_data(io_exe_lsu_bits_rs2_data)
	);
	assign io_prf_alu_req_rs1 = io_iss_alu_bits_p_rs1;
	assign io_prf_alu_req_rs2 = io_iss_alu_bits_p_rs2;
	assign io_prf_lsu_req_rs1 = io_iss_lsu_bits_p_rs1;
	assign io_prf_lsu_req_rs2 = io_iss_lsu_bits_p_rs2;
endmodule
module PRF (
	clock,
	reset,
	io_alu_req_rs1,
	io_alu_req_rs2,
	io_alu_resp_rs1,
	io_alu_resp_rs2,
	io_lsu_req_rs1,
	io_lsu_req_rs2,
	io_lsu_resp_rs1,
	io_lsu_resp_rs2,
	io_wb_alu_valid,
	io_wb_alu_pdst,
	io_wb_alu_data,
	io_wb_lsu_valid,
	io_wb_lsu_pdst,
	io_wb_lsu_data
);
	input clock;
	input reset;
	input [5:0] io_alu_req_rs1;
	input [5:0] io_alu_req_rs2;
	output wire [63:0] io_alu_resp_rs1;
	output wire [63:0] io_alu_resp_rs2;
	input [5:0] io_lsu_req_rs1;
	input [5:0] io_lsu_req_rs2;
	output wire [63:0] io_lsu_resp_rs1;
	output wire [63:0] io_lsu_resp_rs2;
	input io_wb_alu_valid;
	input [5:0] io_wb_alu_pdst;
	input [63:0] io_wb_alu_data;
	input io_wb_lsu_valid;
	input [5:0] io_wb_lsu_pdst;
	input [63:0] io_wb_lsu_data;
	reg [63:0] regfile_0;
	reg [63:0] regfile_1;
	reg [63:0] regfile_2;
	reg [63:0] regfile_3;
	reg [63:0] regfile_4;
	reg [63:0] regfile_5;
	reg [63:0] regfile_6;
	reg [63:0] regfile_7;
	reg [63:0] regfile_8;
	reg [63:0] regfile_9;
	reg [63:0] regfile_10;
	reg [63:0] regfile_11;
	reg [63:0] regfile_12;
	reg [63:0] regfile_13;
	reg [63:0] regfile_14;
	reg [63:0] regfile_15;
	reg [63:0] regfile_16;
	reg [63:0] regfile_17;
	reg [63:0] regfile_18;
	reg [63:0] regfile_19;
	reg [63:0] regfile_20;
	reg [63:0] regfile_21;
	reg [63:0] regfile_22;
	reg [63:0] regfile_23;
	reg [63:0] regfile_24;
	reg [63:0] regfile_25;
	reg [63:0] regfile_26;
	reg [63:0] regfile_27;
	reg [63:0] regfile_28;
	reg [63:0] regfile_29;
	reg [63:0] regfile_30;
	reg [63:0] regfile_31;
	reg [63:0] regfile_32;
	reg [63:0] regfile_33;
	reg [63:0] regfile_34;
	reg [63:0] regfile_35;
	reg [63:0] regfile_36;
	reg [63:0] regfile_37;
	reg [63:0] regfile_38;
	reg [63:0] regfile_39;
	reg [63:0] regfile_40;
	reg [63:0] regfile_41;
	reg [63:0] regfile_42;
	reg [63:0] regfile_43;
	reg [63:0] regfile_44;
	reg [63:0] regfile_45;
	reg [63:0] regfile_46;
	reg [63:0] regfile_47;
	reg [63:0] regfile_48;
	reg [63:0] regfile_49;
	reg [63:0] regfile_50;
	reg [63:0] regfile_51;
	reg [63:0] regfile_52;
	reg [63:0] regfile_53;
	reg [63:0] regfile_54;
	reg [63:0] regfile_55;
	reg [63:0] regfile_56;
	reg [63:0] regfile_57;
	reg [63:0] regfile_58;
	reg [63:0] regfile_59;
	reg [63:0] regfile_60;
	reg [63:0] regfile_61;
	reg [63:0] regfile_62;
	reg [63:0] regfile_63;
	wire [4095:0] _GEN = {regfile_63, regfile_62, regfile_61, regfile_60, regfile_59, regfile_58, regfile_57, regfile_56, regfile_55, regfile_54, regfile_53, regfile_52, regfile_51, regfile_50, regfile_49, regfile_48, regfile_47, regfile_46, regfile_45, regfile_44, regfile_43, regfile_42, regfile_41, regfile_40, regfile_39, regfile_38, regfile_37, regfile_36, regfile_35, regfile_34, regfile_33, regfile_32, regfile_31, regfile_30, regfile_29, regfile_28, regfile_27, regfile_26, regfile_25, regfile_24, regfile_23, regfile_22, regfile_21, regfile_20, regfile_19, regfile_18, regfile_17, regfile_16, regfile_15, regfile_14, regfile_13, regfile_12, regfile_11, regfile_10, regfile_9, regfile_8, regfile_7, regfile_6, regfile_5, regfile_4, regfile_3, regfile_2, regfile_1, regfile_0};
	always @(posedge clock)
		if (reset) begin
			regfile_0 <= 64'h0000000000000000;
			regfile_1 <= 64'h0000000000000000;
			regfile_2 <= 64'h0000000000000000;
			regfile_3 <= 64'h0000000000000000;
			regfile_4 <= 64'h0000000000000000;
			regfile_5 <= 64'h0000000000000000;
			regfile_6 <= 64'h0000000000000000;
			regfile_7 <= 64'h0000000000000000;
			regfile_8 <= 64'h0000000000000000;
			regfile_9 <= 64'h0000000000000000;
			regfile_10 <= 64'h0000000000000000;
			regfile_11 <= 64'h0000000000000000;
			regfile_12 <= 64'h0000000000000000;
			regfile_13 <= 64'h0000000000000000;
			regfile_14 <= 64'h0000000000000000;
			regfile_15 <= 64'h0000000000000000;
			regfile_16 <= 64'h0000000000000000;
			regfile_17 <= 64'h0000000000000000;
			regfile_18 <= 64'h0000000000000000;
			regfile_19 <= 64'h0000000000000000;
			regfile_20 <= 64'h0000000000000000;
			regfile_21 <= 64'h0000000000000000;
			regfile_22 <= 64'h0000000000000000;
			regfile_23 <= 64'h0000000000000000;
			regfile_24 <= 64'h0000000000000000;
			regfile_25 <= 64'h0000000000000000;
			regfile_26 <= 64'h0000000000000000;
			regfile_27 <= 64'h0000000000000000;
			regfile_28 <= 64'h0000000000000000;
			regfile_29 <= 64'h0000000000000000;
			regfile_30 <= 64'h0000000000000000;
			regfile_31 <= 64'h0000000000000000;
			regfile_32 <= 64'h0000000000000000;
			regfile_33 <= 64'h0000000000000000;
			regfile_34 <= 64'h0000000000000000;
			regfile_35 <= 64'h0000000000000000;
			regfile_36 <= 64'h0000000000000000;
			regfile_37 <= 64'h0000000000000000;
			regfile_38 <= 64'h0000000000000000;
			regfile_39 <= 64'h0000000000000000;
			regfile_40 <= 64'h0000000000000000;
			regfile_41 <= 64'h0000000000000000;
			regfile_42 <= 64'h0000000000000000;
			regfile_43 <= 64'h0000000000000000;
			regfile_44 <= 64'h0000000000000000;
			regfile_45 <= 64'h0000000000000000;
			regfile_46 <= 64'h0000000000000000;
			regfile_47 <= 64'h0000000000000000;
			regfile_48 <= 64'h0000000000000000;
			regfile_49 <= 64'h0000000000000000;
			regfile_50 <= 64'h0000000000000000;
			regfile_51 <= 64'h0000000000000000;
			regfile_52 <= 64'h0000000000000000;
			regfile_53 <= 64'h0000000000000000;
			regfile_54 <= 64'h0000000000000000;
			regfile_55 <= 64'h0000000000000000;
			regfile_56 <= 64'h0000000000000000;
			regfile_57 <= 64'h0000000000000000;
			regfile_58 <= 64'h0000000000000000;
			regfile_59 <= 64'h0000000000000000;
			regfile_60 <= 64'h0000000000000000;
			regfile_61 <= 64'h0000000000000000;
			regfile_62 <= 64'h0000000000000000;
			regfile_63 <= 64'h0000000000000000;
		end
		else begin : sv2v_autoblock_1
			reg _GEN_0;
			reg _GEN_1;
			_GEN_1 = io_wb_lsu_valid & |io_wb_lsu_pdst;
			_GEN_0 = io_wb_alu_valid & |io_wb_alu_pdst;
			if (_GEN_1 & ~(|io_wb_lsu_pdst))
				regfile_0 <= io_wb_lsu_data;
			else if (_GEN_0 & ~(|io_wb_alu_pdst))
				regfile_0 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h01))
				regfile_1 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h01))
				regfile_1 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h02))
				regfile_2 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h02))
				regfile_2 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h03))
				regfile_3 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h03))
				regfile_3 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h04))
				regfile_4 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h04))
				regfile_4 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h05))
				regfile_5 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h05))
				regfile_5 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h06))
				regfile_6 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h06))
				regfile_6 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h07))
				regfile_7 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h07))
				regfile_7 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h08))
				regfile_8 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h08))
				regfile_8 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h09))
				regfile_9 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h09))
				regfile_9 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h0a))
				regfile_10 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h0a))
				regfile_10 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h0b))
				regfile_11 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h0b))
				regfile_11 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h0c))
				regfile_12 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h0c))
				regfile_12 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h0d))
				regfile_13 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h0d))
				regfile_13 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h0e))
				regfile_14 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h0e))
				regfile_14 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h0f))
				regfile_15 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h0f))
				regfile_15 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h10))
				regfile_16 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h10))
				regfile_16 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h11))
				regfile_17 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h11))
				regfile_17 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h12))
				regfile_18 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h12))
				regfile_18 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h13))
				regfile_19 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h13))
				regfile_19 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h14))
				regfile_20 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h14))
				regfile_20 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h15))
				regfile_21 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h15))
				regfile_21 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h16))
				regfile_22 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h16))
				regfile_22 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h17))
				regfile_23 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h17))
				regfile_23 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h18))
				regfile_24 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h18))
				regfile_24 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h19))
				regfile_25 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h19))
				regfile_25 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h1a))
				regfile_26 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h1a))
				regfile_26 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h1b))
				regfile_27 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h1b))
				regfile_27 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h1c))
				regfile_28 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h1c))
				regfile_28 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h1d))
				regfile_29 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h1d))
				regfile_29 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h1e))
				regfile_30 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h1e))
				regfile_30 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h1f))
				regfile_31 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h1f))
				regfile_31 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h20))
				regfile_32 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h20))
				regfile_32 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h21))
				regfile_33 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h21))
				regfile_33 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h22))
				regfile_34 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h22))
				regfile_34 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h23))
				regfile_35 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h23))
				regfile_35 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h24))
				regfile_36 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h24))
				regfile_36 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h25))
				regfile_37 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h25))
				regfile_37 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h26))
				regfile_38 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h26))
				regfile_38 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h27))
				regfile_39 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h27))
				regfile_39 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h28))
				regfile_40 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h28))
				regfile_40 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h29))
				regfile_41 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h29))
				regfile_41 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h2a))
				regfile_42 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h2a))
				regfile_42 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h2b))
				regfile_43 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h2b))
				regfile_43 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h2c))
				regfile_44 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h2c))
				regfile_44 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h2d))
				regfile_45 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h2d))
				regfile_45 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h2e))
				regfile_46 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h2e))
				regfile_46 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h2f))
				regfile_47 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h2f))
				regfile_47 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h30))
				regfile_48 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h30))
				regfile_48 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h31))
				regfile_49 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h31))
				regfile_49 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h32))
				regfile_50 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h32))
				regfile_50 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h33))
				regfile_51 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h33))
				regfile_51 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h34))
				regfile_52 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h34))
				regfile_52 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h35))
				regfile_53 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h35))
				regfile_53 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h36))
				regfile_54 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h36))
				regfile_54 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h37))
				regfile_55 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h37))
				regfile_55 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h38))
				regfile_56 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h38))
				regfile_56 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h39))
				regfile_57 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h39))
				regfile_57 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h3a))
				regfile_58 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h3a))
				regfile_58 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h3b))
				regfile_59 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h3b))
				regfile_59 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h3c))
				regfile_60 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h3c))
				regfile_60 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h3d))
				regfile_61 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h3d))
				regfile_61 <= io_wb_alu_data;
			if (_GEN_1 & (io_wb_lsu_pdst == 6'h3e))
				regfile_62 <= io_wb_lsu_data;
			else if (_GEN_0 & (io_wb_alu_pdst == 6'h3e))
				regfile_62 <= io_wb_alu_data;
			if (_GEN_1 & (&io_wb_lsu_pdst))
				regfile_63 <= io_wb_lsu_data;
			else if (_GEN_0 & (&io_wb_alu_pdst))
				regfile_63 <= io_wb_alu_data;
		end
	assign io_alu_resp_rs1 = (io_alu_req_rs1 == 6'h00 ? 64'h0000000000000000 : (io_wb_alu_valid & (io_wb_alu_pdst == io_alu_req_rs1) ? io_wb_alu_data : (io_wb_lsu_valid & (io_wb_lsu_pdst == io_alu_req_rs1) ? io_wb_lsu_data : _GEN[io_alu_req_rs1 * 64+:64])));
	assign io_alu_resp_rs2 = (io_alu_req_rs2 == 6'h00 ? 64'h0000000000000000 : (io_wb_alu_valid & (io_wb_alu_pdst == io_alu_req_rs2) ? io_wb_alu_data : (io_wb_lsu_valid & (io_wb_lsu_pdst == io_alu_req_rs2) ? io_wb_lsu_data : _GEN[io_alu_req_rs2 * 64+:64])));
	assign io_lsu_resp_rs1 = (io_lsu_req_rs1 == 6'h00 ? 64'h0000000000000000 : (io_wb_alu_valid & (io_wb_alu_pdst == io_lsu_req_rs1) ? io_wb_alu_data : (io_wb_lsu_valid & (io_wb_lsu_pdst == io_lsu_req_rs1) ? io_wb_lsu_data : _GEN[io_lsu_req_rs1 * 64+:64])));
	assign io_lsu_resp_rs2 = (io_lsu_req_rs2 == 6'h00 ? 64'h0000000000000000 : (io_wb_alu_valid & (io_wb_alu_pdst == io_lsu_req_rs2) ? io_wb_alu_data : (io_wb_lsu_valid & (io_wb_lsu_pdst == io_lsu_req_rs2) ? io_wb_lsu_data : _GEN[io_lsu_req_rs2 * 64+:64])));
endmodule
module ALU_Unit (
	io_req_valid,
	io_req_bits_uop_pc,
	io_req_bits_uop_alu_op,
	io_req_bits_uop_op1_sel,
	io_req_bits_uop_op2_sel,
	io_req_bits_uop_imm,
	io_req_bits_uop_is_w,
	io_req_bits_uop_br_type,
	io_req_bits_uop_p_rd,
	io_req_bits_uop_rob_idx,
	io_req_bits_uop_exception,
	io_req_bits_uop_pred_taken,
	io_req_bits_uop_pred_target,
	io_req_bits_rs1_data,
	io_req_bits_rs2_data,
	io_cdb_valid,
	io_cdb_bits_rob_idx,
	io_cdb_bits_p_rd,
	io_cdb_bits_data,
	io_cdb_bits_exc,
	io_cdb_bits_is_branch,
	io_cdb_bits_br_taken,
	io_cdb_bits_br_target,
	io_cdb_bits_br_pc,
	io_br_redirect,
	io_br_redirect_pc,
	io_br_res_valid,
	io_br_res_bits_mispredicted,
	io_br_res_bits_rob_idx
);
	input io_req_valid;
	input [63:0] io_req_bits_uop_pc;
	input [9:0] io_req_bits_uop_alu_op;
	input [1:0] io_req_bits_uop_op1_sel;
	input [2:0] io_req_bits_uop_op2_sel;
	input [63:0] io_req_bits_uop_imm;
	input io_req_bits_uop_is_w;
	input [3:0] io_req_bits_uop_br_type;
	input [5:0] io_req_bits_uop_p_rd;
	input [3:0] io_req_bits_uop_rob_idx;
	input io_req_bits_uop_exception;
	input io_req_bits_uop_pred_taken;
	input [63:0] io_req_bits_uop_pred_target;
	input [63:0] io_req_bits_rs1_data;
	input [63:0] io_req_bits_rs2_data;
	output wire io_cdb_valid;
	output wire [3:0] io_cdb_bits_rob_idx;
	output wire [5:0] io_cdb_bits_p_rd;
	output wire [63:0] io_cdb_bits_data;
	output wire io_cdb_bits_exc;
	output wire io_cdb_bits_is_branch;
	output wire io_cdb_bits_br_taken;
	output wire [63:0] io_cdb_bits_br_target;
	output wire [63:0] io_cdb_bits_br_pc;
	output wire io_br_redirect;
	output wire [63:0] io_br_redirect_pc;
	output wire io_br_res_valid;
	output wire io_br_res_bits_mispredicted;
	output wire [3:0] io_br_res_bits_rob_idx;
	wire [63:0] op1 = (io_req_bits_uop_op1_sel == 2'h1 ? 64'h0000000000000000 : (io_req_bits_uop_op1_sel == 2'h2 ? io_req_bits_uop_pc : io_req_bits_rs1_data));
	wire [63:0] op2 = (io_req_bits_uop_op2_sel == 3'h5 ? 64'h0000000000000004 : (io_req_bits_uop_op2_sel == 3'h2 ? io_req_bits_uop_imm : io_req_bits_rs2_data));
	wire [5:0] shamt = (io_req_bits_uop_is_w ? {1'h0, op2[4:0]} : op2[5:0]);
	wire [126:0] _alu_out_T_7 = {63'h0000000000000000, op1} << shamt;
	wire [63:0] _GEN = {58'h000000000000000, shamt};
	wire [63:0] alu_out = (io_req_bits_uop_alu_op == 10'h009 ? {63'h0000000000000000, op1 < op2} : (io_req_bits_uop_alu_op == 10'h008 ? {63'h0000000000000000, $signed(op1) < $signed(op2)} : (io_req_bits_uop_alu_op == 10'h007 ? $signed($signed(op1) >>> _GEN) : (io_req_bits_uop_alu_op == 10'h006 ? op1 >> _GEN : (io_req_bits_uop_alu_op == 10'h005 ? _alu_out_T_7[63:0] : (io_req_bits_uop_alu_op == 10'h004 ? op1 ^ op2 : (io_req_bits_uop_alu_op == 10'h003 ? op1 | op2 : (io_req_bits_uop_alu_op == 10'h002 ? op1 & op2 : (io_req_bits_uop_alu_op == 10'h001 ? op1 - op2 : (io_req_bits_uop_alu_op == 10'h000 ? op1 + op2 : 64'h0000000000000000))))))))));
	wire is_eq = io_req_bits_rs1_data == io_req_bits_rs2_data;
	wire is_lt = $signed(io_req_bits_rs1_data) < $signed(io_req_bits_rs2_data);
	wire is_ltu = io_req_bits_rs1_data < io_req_bits_rs2_data;
	wire actual_taken = ((io_req_bits_uop_br_type == 4'h8) | (io_req_bits_uop_br_type == 4'h7)) | (io_req_bits_uop_br_type == 4'h4 ? ~is_ltu : (io_req_bits_uop_br_type == 4'h6 ? is_ltu : (io_req_bits_uop_br_type == 4'h3 ? ~is_lt : (io_req_bits_uop_br_type == 4'h5 ? is_lt : (io_req_bits_uop_br_type == 4'h1 ? ~is_eq : (io_req_bits_uop_br_type == 4'h2) & is_eq)))));
	wire _is_jump_T_1 = io_req_bits_uop_br_type == 4'h8;
	wire [63:0] actual_target = (_is_jump_T_1 ? (io_req_bits_rs1_data + io_req_bits_uop_imm) & 64'hfffffffffffffffe : io_req_bits_uop_pc + io_req_bits_uop_imm);
	wire is_jump = (io_req_bits_uop_br_type == 4'h7) | _is_jump_T_1;
	wire _io_br_res_valid_T = io_req_bits_uop_br_type == 4'h1;
	wire _io_br_res_valid_T_1 = io_req_bits_uop_br_type == 4'h2;
	wire _io_br_res_valid_T_2 = io_req_bits_uop_br_type == 4'h3;
	wire _io_br_res_valid_T_3 = io_req_bits_uop_br_type == 4'h4;
	wire _io_br_res_valid_T_4 = io_req_bits_uop_br_type == 4'h5;
	wire _io_br_res_valid_T_5 = io_req_bits_uop_br_type == 4'h6;
	wire is_branch_inst = (((((_io_br_res_valid_T | _io_br_res_valid_T_1) | _io_br_res_valid_T_2) | _io_br_res_valid_T_3) | _io_br_res_valid_T_4) | _io_br_res_valid_T_5) | is_jump;
	wire is_mispredict = is_branch_inst & ((actual_taken != io_req_bits_uop_pred_taken) | (actual_taken & (actual_target != io_req_bits_uop_pred_target)));
	wire [63:0] _io_cdb_bits_data_T = io_req_bits_uop_pc + 64'h0000000000000004;
	assign io_cdb_valid = io_req_valid;
	assign io_cdb_bits_rob_idx = io_req_bits_uop_rob_idx;
	assign io_cdb_bits_p_rd = io_req_bits_uop_p_rd;
	assign io_cdb_bits_data = (is_jump ? _io_cdb_bits_data_T : (io_req_bits_uop_is_w ? {{32 {alu_out[31]}}, alu_out[31:0]} : alu_out));
	assign io_cdb_bits_exc = io_req_bits_uop_exception;
	assign io_cdb_bits_is_branch = is_branch_inst;
	assign io_cdb_bits_br_taken = actual_taken;
	assign io_cdb_bits_br_target = actual_target;
	assign io_cdb_bits_br_pc = io_req_bits_uop_pc;
	assign io_br_redirect = io_req_valid & is_mispredict;
	assign io_br_redirect_pc = (actual_taken ? actual_target : _io_cdb_bits_data_T);
	assign io_br_res_valid = io_req_valid & ((((((_io_br_res_valid_T | _io_br_res_valid_T_1) | _io_br_res_valid_T_2) | _io_br_res_valid_T_3) | _io_br_res_valid_T_4) | _io_br_res_valid_T_5) | is_jump);
	assign io_br_res_bits_mispredicted = is_mispredict;
	assign io_br_res_bits_rob_idx = io_req_bits_uop_rob_idx;
endmodule
module LSU_Unit (
	clock,
	reset,
	io_req_ready,
	io_req_valid,
	io_req_bits_uop_imm,
	io_req_bits_uop_mem_cmd,
	io_req_bits_uop_mem_size,
	io_req_bits_uop_mem_signed,
	io_req_bits_uop_p_rd,
	io_req_bits_uop_rob_idx,
	io_req_bits_uop_exception,
	io_req_bits_rs1_data,
	io_req_bits_rs2_data,
	io_cdb_valid,
	io_cdb_bits_rob_idx,
	io_cdb_bits_p_rd,
	io_cdb_bits_data,
	io_cdb_bits_exc,
	io_dmem_req_ready,
	io_dmem_req_valid,
	io_dmem_req_bits_addr,
	io_dmem_req_bits_data,
	io_dmem_req_bits_cmd,
	io_dmem_req_bits_size,
	io_dmem_resp_valid,
	io_dmem_resp_bits_data,
	io_commit_store_0_valid,
	io_commit_store_0_bits,
	io_commit_store_1_valid,
	io_commit_store_1_bits,
	io_flush_mispredict,
	io_mispredict_rob_idx,
	io_rob_head_idx,
	io_flush
);
	input clock;
	input reset;
	output wire io_req_ready;
	input io_req_valid;
	input [63:0] io_req_bits_uop_imm;
	input [2:0] io_req_bits_uop_mem_cmd;
	input [1:0] io_req_bits_uop_mem_size;
	input io_req_bits_uop_mem_signed;
	input [5:0] io_req_bits_uop_p_rd;
	input [3:0] io_req_bits_uop_rob_idx;
	input io_req_bits_uop_exception;
	input [63:0] io_req_bits_rs1_data;
	input [63:0] io_req_bits_rs2_data;
	output wire io_cdb_valid;
	output wire [3:0] io_cdb_bits_rob_idx;
	output wire [5:0] io_cdb_bits_p_rd;
	output wire [63:0] io_cdb_bits_data;
	output wire io_cdb_bits_exc;
	input io_dmem_req_ready;
	output wire io_dmem_req_valid;
	output wire [63:0] io_dmem_req_bits_addr;
	output wire [63:0] io_dmem_req_bits_data;
	output wire [2:0] io_dmem_req_bits_cmd;
	output wire [1:0] io_dmem_req_bits_size;
	input io_dmem_resp_valid;
	input [63:0] io_dmem_resp_bits_data;
	input io_commit_store_0_valid;
	input [3:0] io_commit_store_0_bits;
	input io_commit_store_1_valid;
	input [3:0] io_commit_store_1_bits;
	input io_flush_mispredict;
	input [3:0] io_mispredict_rob_idx;
	input [3:0] io_rob_head_idx;
	input io_flush;
	wire io_req_ready_0;
	wire [63:0] _effective_addr_T = io_req_bits_rs1_data + io_req_bits_uop_imm;
	reg [63:0] sb_addr_0;
	reg [63:0] sb_addr_1;
	reg [63:0] sb_addr_2;
	reg [63:0] sb_addr_3;
	reg [63:0] sb_addr_4;
	reg [63:0] sb_addr_5;
	reg [63:0] sb_addr_6;
	reg [63:0] sb_addr_7;
	reg [63:0] sb_addr_8;
	reg [63:0] sb_addr_9;
	reg [63:0] sb_addr_10;
	reg [63:0] sb_addr_11;
	reg [63:0] sb_addr_12;
	reg [63:0] sb_addr_13;
	reg [63:0] sb_addr_14;
	reg [63:0] sb_addr_15;
	reg [63:0] sb_data_0;
	reg [63:0] sb_data_1;
	reg [63:0] sb_data_2;
	reg [63:0] sb_data_3;
	reg [63:0] sb_data_4;
	reg [63:0] sb_data_5;
	reg [63:0] sb_data_6;
	reg [63:0] sb_data_7;
	reg [63:0] sb_data_8;
	reg [63:0] sb_data_9;
	reg [63:0] sb_data_10;
	reg [63:0] sb_data_11;
	reg [63:0] sb_data_12;
	reg [63:0] sb_data_13;
	reg [63:0] sb_data_14;
	reg [63:0] sb_data_15;
	reg [1:0] sb_size_0;
	reg [1:0] sb_size_1;
	reg [1:0] sb_size_2;
	reg [1:0] sb_size_3;
	reg [1:0] sb_size_4;
	reg [1:0] sb_size_5;
	reg [1:0] sb_size_6;
	reg [1:0] sb_size_7;
	reg [1:0] sb_size_8;
	reg [1:0] sb_size_9;
	reg [1:0] sb_size_10;
	reg [1:0] sb_size_11;
	reg [1:0] sb_size_12;
	reg [1:0] sb_size_13;
	reg [1:0] sb_size_14;
	reg [1:0] sb_size_15;
	reg sb_valid_0;
	reg sb_valid_1;
	reg sb_valid_2;
	reg sb_valid_3;
	reg sb_valid_4;
	reg sb_valid_5;
	reg sb_valid_6;
	reg sb_valid_7;
	reg sb_valid_8;
	reg sb_valid_9;
	reg sb_valid_10;
	reg sb_valid_11;
	reg sb_valid_12;
	reg sb_valid_13;
	reg sb_valid_14;
	reg sb_valid_15;
	wire is_store = io_req_bits_uop_mem_cmd == 3'h2;
	wire is_load = io_req_bits_uop_mem_cmd == 3'h1;
	wire _GEN = io_req_ready_0 & io_req_valid;
	wire _GEN_0 = _GEN & is_store;
	reg [63:0] c_sq_0_addr;
	reg [63:0] c_sq_0_data;
	reg [1:0] c_sq_0_size;
	reg [63:0] c_sq_1_addr;
	reg [63:0] c_sq_1_data;
	reg [1:0] c_sq_1_size;
	reg [63:0] c_sq_2_addr;
	reg [63:0] c_sq_2_data;
	reg [1:0] c_sq_2_size;
	reg [63:0] c_sq_3_addr;
	reg [63:0] c_sq_3_data;
	reg [1:0] c_sq_3_size;
	reg [63:0] c_sq_4_addr;
	reg [63:0] c_sq_4_data;
	reg [1:0] c_sq_4_size;
	reg [63:0] c_sq_5_addr;
	reg [63:0] c_sq_5_data;
	reg [1:0] c_sq_5_size;
	reg [63:0] c_sq_6_addr;
	reg [63:0] c_sq_6_data;
	reg [1:0] c_sq_6_size;
	reg [63:0] c_sq_7_addr;
	reg [63:0] c_sq_7_data;
	reg [1:0] c_sq_7_size;
	reg [63:0] c_sq_8_addr;
	reg [63:0] c_sq_8_data;
	reg [1:0] c_sq_8_size;
	reg [63:0] c_sq_9_addr;
	reg [63:0] c_sq_9_data;
	reg [1:0] c_sq_9_size;
	reg [63:0] c_sq_10_addr;
	reg [63:0] c_sq_10_data;
	reg [1:0] c_sq_10_size;
	reg [63:0] c_sq_11_addr;
	reg [63:0] c_sq_11_data;
	reg [1:0] c_sq_11_size;
	reg [63:0] c_sq_12_addr;
	reg [63:0] c_sq_12_data;
	reg [1:0] c_sq_12_size;
	reg [63:0] c_sq_13_addr;
	reg [63:0] c_sq_13_data;
	reg [1:0] c_sq_13_size;
	reg [63:0] c_sq_14_addr;
	reg [63:0] c_sq_14_data;
	reg [1:0] c_sq_14_size;
	reg [63:0] c_sq_15_addr;
	reg [63:0] c_sq_15_data;
	reg [1:0] c_sq_15_size;
	reg c_sq_val_0;
	reg c_sq_val_1;
	reg c_sq_val_2;
	reg c_sq_val_3;
	reg c_sq_val_4;
	reg c_sq_val_5;
	reg c_sq_val_6;
	reg c_sq_val_7;
	reg c_sq_val_8;
	reg c_sq_val_9;
	reg c_sq_val_10;
	reg c_sq_val_11;
	reg c_sq_val_12;
	reg c_sq_val_13;
	reg c_sq_val_14;
	reg c_sq_val_15;
	reg [3:0] c_sq_head;
	reg [3:0] c_sq_tail;
	reg state;
	reg [1:0] load_uop_reg_mem_size;
	reg load_uop_reg_mem_signed;
	reg [5:0] load_uop_reg_p_rd;
	reg [3:0] load_uop_reg_rob_idx;
	reg load_uop_reg_exception;
	reg [63:0] load_addr_reg;
	wire [15:0] _GEN_1 = {c_sq_val_15, c_sq_val_14, c_sq_val_13, c_sq_val_12, c_sq_val_11, c_sq_val_10, c_sq_val_9, c_sq_val_8, c_sq_val_7, c_sq_val_6, c_sq_val_5, c_sq_val_4, c_sq_val_3, c_sq_val_2, c_sq_val_1, c_sq_val_0};
	wire _GEN_2 = _GEN_1[c_sq_head];
	wire do_load_req = (((io_req_valid & is_load) & ~_GEN_2) & ({sb_valid_15, sb_valid_14, sb_valid_13, sb_valid_12, sb_valid_11, sb_valid_10, sb_valid_9, sb_valid_8, sb_valid_7, sb_valid_6, sb_valid_5, sb_valid_4, sb_valid_3, sb_valid_2, sb_valid_1, sb_valid_0} == 16'h0000)) & ~state;
	assign io_req_ready_0 = ~state & (is_store | do_load_req);
	wire _GEN_3 = state & io_dmem_resp_valid;
	wire io_dmem_req_valid_0 = do_load_req | _GEN_2;
	wire [1023:0] _GEN_4 = {c_sq_15_addr, c_sq_14_addr, c_sq_13_addr, c_sq_12_addr, c_sq_11_addr, c_sq_10_addr, c_sq_9_addr, c_sq_8_addr, c_sq_7_addr, c_sq_6_addr, c_sq_5_addr, c_sq_4_addr, c_sq_3_addr, c_sq_2_addr, c_sq_1_addr, c_sq_0_addr};
	wire [1023:0] _GEN_5 = {c_sq_15_data, c_sq_14_data, c_sq_13_data, c_sq_12_data, c_sq_11_data, c_sq_10_data, c_sq_9_data, c_sq_8_data, c_sq_7_data, c_sq_6_data, c_sq_5_data, c_sq_4_data, c_sq_3_data, c_sq_2_data, c_sq_1_data, c_sq_0_data};
	wire [31:0] _GEN_6 = {c_sq_15_size, c_sq_14_size, c_sq_13_size, c_sq_12_size, c_sq_11_size, c_sq_10_size, c_sq_9_size, c_sq_8_size, c_sq_7_size, c_sq_6_size, c_sq_5_size, c_sq_4_size, c_sq_3_size, c_sq_2_size, c_sq_1_size, c_sq_0_size};
	wire [63:0] shifted_data = io_dmem_resp_bits_data >> {58'h000000000000000, load_addr_reg[2:0], 3'h0};
	wire [255:0] _GEN_7 = {(load_uop_reg_mem_signed ? {32 {shifted_data[31]}} : 32'h00000000), shifted_data[31:0], (load_uop_reg_mem_signed ? {48 {shifted_data[15]}} : 48'h000000000000), shifted_data[15:0], (load_uop_reg_mem_signed ? {56 {shifted_data[7]}} : 56'h00000000000000), shifted_data[7:0], io_dmem_resp_bits_data};
	wire _GEN_8 = _GEN_0 | ~_GEN_3;
	always @(posedge clock) begin : sv2v_autoblock_1
		reg [255:0] _GEN_9;
		reg _GEN_10;
		reg _GEN_11;
		reg _GEN_12;
		reg _GEN_13;
		reg _GEN_14;
		reg _GEN_15;
		reg _GEN_16;
		reg _GEN_17;
		reg _GEN_18;
		reg _GEN_19;
		reg _GEN_20;
		reg _GEN_21;
		reg _GEN_22;
		reg _GEN_23;
		reg _GEN_24;
		reg _GEN_25;
		reg [1023:0] _GEN_26;
		reg _GEN_27;
		reg _GEN_28;
		reg _GEN_29;
		reg _GEN_30;
		reg _GEN_31;
		reg _GEN_32;
		reg _GEN_33;
		reg _GEN_34;
		reg _GEN_35;
		reg _GEN_36;
		reg _GEN_37;
		reg _GEN_38;
		reg _GEN_39;
		reg _GEN_40;
		reg _GEN_41;
		reg _GEN_42;
		reg [1023:0] _GEN_43;
		reg [31:0] _GEN_44;
		reg [3:0] t_idx;
		reg _GEN_45;
		reg _GEN_46;
		reg _GEN_47;
		reg _GEN_48;
		reg _GEN_49;
		reg _GEN_50;
		reg _GEN_51;
		reg _GEN_52;
		reg _GEN_53;
		reg _GEN_54;
		reg _GEN_55;
		reg _GEN_56;
		reg _GEN_57;
		reg _GEN_58;
		reg _GEN_59;
		reg _GEN_60;
		_GEN_9 = {{2 {io_req_bits_rs2_data[31:0]}}, {2 {{2 {io_req_bits_rs2_data[15:0]}}}}, {2 {{2 {{2 {io_req_bits_rs2_data[7:0]}}}}}}, io_req_bits_rs2_data};
		_GEN_26 = {sb_addr_15, sb_addr_14, sb_addr_13, sb_addr_12, sb_addr_11, sb_addr_10, sb_addr_9, sb_addr_8, sb_addr_7, sb_addr_6, sb_addr_5, sb_addr_4, sb_addr_3, sb_addr_2, sb_addr_1, sb_addr_0};
		_GEN_43 = {sb_data_15, sb_data_14, sb_data_13, sb_data_12, sb_data_11, sb_data_10, sb_data_9, sb_data_8, sb_data_7, sb_data_6, sb_data_5, sb_data_4, sb_data_3, sb_data_2, sb_data_1, sb_data_0};
		_GEN_44 = {sb_size_15, sb_size_14, sb_size_13, sb_size_12, sb_size_11, sb_size_10, sb_size_9, sb_size_8, sb_size_7, sb_size_6, sb_size_5, sb_size_4, sb_size_3, sb_size_2, sb_size_1, sb_size_0};
		_GEN_10 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h0);
		_GEN_11 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h1);
		_GEN_12 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h2);
		_GEN_13 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h3);
		_GEN_14 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h4);
		_GEN_15 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h5);
		_GEN_16 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h6);
		_GEN_17 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h7);
		_GEN_18 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h8);
		_GEN_19 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'h9);
		_GEN_20 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'ha);
		_GEN_21 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'hb);
		_GEN_22 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'hc);
		_GEN_23 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'hd);
		_GEN_24 = _GEN_0 & (io_req_bits_uop_rob_idx == 4'he);
		_GEN_25 = _GEN_0 & (&io_req_bits_uop_rob_idx);
		_GEN_27 = io_commit_store_0_valid & (c_sq_tail == 4'h0);
		_GEN_28 = io_commit_store_0_valid & (c_sq_tail == 4'h1);
		_GEN_29 = io_commit_store_0_valid & (c_sq_tail == 4'h2);
		_GEN_30 = io_commit_store_0_valid & (c_sq_tail == 4'h3);
		_GEN_31 = io_commit_store_0_valid & (c_sq_tail == 4'h4);
		_GEN_32 = io_commit_store_0_valid & (c_sq_tail == 4'h5);
		_GEN_33 = io_commit_store_0_valid & (c_sq_tail == 4'h6);
		_GEN_34 = io_commit_store_0_valid & (c_sq_tail == 4'h7);
		_GEN_35 = io_commit_store_0_valid & (c_sq_tail == 4'h8);
		_GEN_36 = io_commit_store_0_valid & (c_sq_tail == 4'h9);
		_GEN_37 = io_commit_store_0_valid & (c_sq_tail == 4'ha);
		_GEN_38 = io_commit_store_0_valid & (c_sq_tail == 4'hb);
		_GEN_39 = io_commit_store_0_valid & (c_sq_tail == 4'hc);
		_GEN_40 = io_commit_store_0_valid & (c_sq_tail == 4'hd);
		_GEN_41 = io_commit_store_0_valid & (c_sq_tail == 4'he);
		_GEN_42 = io_commit_store_0_valid & (&c_sq_tail);
		t_idx = (io_commit_store_0_valid ? c_sq_tail + 4'h1 : c_sq_tail);
		_GEN_45 = t_idx == 4'h0;
		_GEN_46 = t_idx == 4'h1;
		_GEN_47 = t_idx == 4'h2;
		_GEN_48 = t_idx == 4'h3;
		_GEN_49 = t_idx == 4'h4;
		_GEN_50 = t_idx == 4'h5;
		_GEN_51 = t_idx == 4'h6;
		_GEN_52 = t_idx == 4'h7;
		_GEN_53 = t_idx == 4'h8;
		_GEN_54 = t_idx == 4'h9;
		_GEN_55 = t_idx == 4'ha;
		_GEN_56 = t_idx == 4'hb;
		_GEN_57 = t_idx == 4'hc;
		_GEN_58 = t_idx == 4'hd;
		_GEN_59 = t_idx == 4'he;
		_GEN_60 = _GEN & is_load;
		if (_GEN_10) begin
			sb_addr_0 <= _effective_addr_T;
			sb_data_0 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_0 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_11) begin
			sb_addr_1 <= _effective_addr_T;
			sb_data_1 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_1 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_12) begin
			sb_addr_2 <= _effective_addr_T;
			sb_data_2 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_2 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_13) begin
			sb_addr_3 <= _effective_addr_T;
			sb_data_3 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_3 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_14) begin
			sb_addr_4 <= _effective_addr_T;
			sb_data_4 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_4 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_15) begin
			sb_addr_5 <= _effective_addr_T;
			sb_data_5 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_5 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_16) begin
			sb_addr_6 <= _effective_addr_T;
			sb_data_6 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_6 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_17) begin
			sb_addr_7 <= _effective_addr_T;
			sb_data_7 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_7 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_18) begin
			sb_addr_8 <= _effective_addr_T;
			sb_data_8 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_8 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_19) begin
			sb_addr_9 <= _effective_addr_T;
			sb_data_9 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_9 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_20) begin
			sb_addr_10 <= _effective_addr_T;
			sb_data_10 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_10 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_21) begin
			sb_addr_11 <= _effective_addr_T;
			sb_data_11 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_11 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_22) begin
			sb_addr_12 <= _effective_addr_T;
			sb_data_12 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_12 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_23) begin
			sb_addr_13 <= _effective_addr_T;
			sb_data_13 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_13 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_24) begin
			sb_addr_14 <= _effective_addr_T;
			sb_data_14 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_14 <= io_req_bits_uop_mem_size;
		end
		if (_GEN_25) begin
			sb_addr_15 <= _effective_addr_T;
			sb_data_15 <= _GEN_9[io_req_bits_uop_mem_size * 64+:64];
			sb_size_15 <= io_req_bits_uop_mem_size;
		end
		if (io_commit_store_1_valid & _GEN_45) begin
			c_sq_0_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_0_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_0_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_27) begin
			c_sq_0_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_0_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_0_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_46) begin
			c_sq_1_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_1_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_1_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_28) begin
			c_sq_1_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_1_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_1_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_47) begin
			c_sq_2_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_2_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_2_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_29) begin
			c_sq_2_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_2_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_2_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_48) begin
			c_sq_3_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_3_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_3_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_30) begin
			c_sq_3_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_3_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_3_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_49) begin
			c_sq_4_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_4_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_4_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_31) begin
			c_sq_4_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_4_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_4_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_50) begin
			c_sq_5_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_5_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_5_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_32) begin
			c_sq_5_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_5_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_5_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_51) begin
			c_sq_6_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_6_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_6_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_33) begin
			c_sq_6_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_6_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_6_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_52) begin
			c_sq_7_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_7_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_7_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_34) begin
			c_sq_7_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_7_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_7_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_53) begin
			c_sq_8_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_8_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_8_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_35) begin
			c_sq_8_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_8_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_8_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_54) begin
			c_sq_9_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_9_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_9_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_36) begin
			c_sq_9_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_9_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_9_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_55) begin
			c_sq_10_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_10_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_10_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_37) begin
			c_sq_10_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_10_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_10_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_56) begin
			c_sq_11_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_11_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_11_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_38) begin
			c_sq_11_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_11_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_11_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_57) begin
			c_sq_12_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_12_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_12_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_39) begin
			c_sq_12_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_12_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_12_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_58) begin
			c_sq_13_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_13_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_13_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_40) begin
			c_sq_13_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_13_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_13_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & _GEN_59) begin
			c_sq_14_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_14_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_14_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_41) begin
			c_sq_14_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_14_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_14_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (io_commit_store_1_valid & (&t_idx)) begin
			c_sq_15_addr <= _GEN_26[io_commit_store_1_bits * 64+:64];
			c_sq_15_data <= _GEN_43[io_commit_store_1_bits * 64+:64];
			c_sq_15_size <= _GEN_44[io_commit_store_1_bits * 2+:2];
		end
		else if (_GEN_42) begin
			c_sq_15_addr <= _GEN_26[io_commit_store_0_bits * 64+:64];
			c_sq_15_data <= _GEN_43[io_commit_store_0_bits * 64+:64];
			c_sq_15_size <= _GEN_44[io_commit_store_0_bits * 2+:2];
		end
		if (_GEN_60) begin
			load_uop_reg_mem_size <= io_req_bits_uop_mem_size;
			load_uop_reg_mem_signed <= io_req_bits_uop_mem_signed;
			load_uop_reg_p_rd <= io_req_bits_uop_p_rd;
			load_uop_reg_rob_idx <= io_req_bits_uop_rob_idx;
			load_uop_reg_exception <= io_req_bits_uop_exception;
			load_addr_reg <= _effective_addr_T;
		end
		if (reset) begin
			sb_valid_0 <= 1'h0;
			sb_valid_1 <= 1'h0;
			sb_valid_2 <= 1'h0;
			sb_valid_3 <= 1'h0;
			sb_valid_4 <= 1'h0;
			sb_valid_5 <= 1'h0;
			sb_valid_6 <= 1'h0;
			sb_valid_7 <= 1'h0;
			sb_valid_8 <= 1'h0;
			sb_valid_9 <= 1'h0;
			sb_valid_10 <= 1'h0;
			sb_valid_11 <= 1'h0;
			sb_valid_12 <= 1'h0;
			sb_valid_13 <= 1'h0;
			sb_valid_14 <= 1'h0;
			sb_valid_15 <= 1'h0;
			c_sq_val_0 <= 1'h0;
			c_sq_val_1 <= 1'h0;
			c_sq_val_2 <= 1'h0;
			c_sq_val_3 <= 1'h0;
			c_sq_val_4 <= 1'h0;
			c_sq_val_5 <= 1'h0;
			c_sq_val_6 <= 1'h0;
			c_sq_val_7 <= 1'h0;
			c_sq_val_8 <= 1'h0;
			c_sq_val_9 <= 1'h0;
			c_sq_val_10 <= 1'h0;
			c_sq_val_11 <= 1'h0;
			c_sq_val_12 <= 1'h0;
			c_sq_val_13 <= 1'h0;
			c_sq_val_14 <= 1'h0;
			c_sq_val_15 <= 1'h0;
			c_sq_head <= 4'h0;
			c_sq_tail <= 4'h0;
			state <= 1'h0;
		end
		else begin : sv2v_autoblock_2
			reg _GEN_61;
			reg _GEN_62;
			reg _GEN_63;
			reg _GEN_64;
			reg _GEN_65;
			reg _GEN_66;
			reg _GEN_67;
			reg _GEN_68;
			reg _GEN_69;
			reg _GEN_70;
			reg _GEN_71;
			reg _GEN_72;
			reg _GEN_73;
			reg _GEN_74;
			reg _GEN_75;
			reg _GEN_76;
			reg [3:0] _GEN_77;
			reg _GEN_78;
			reg _GEN_79;
			reg _GEN_80;
			reg _GEN_81;
			reg _GEN_82;
			reg _GEN_83;
			reg _GEN_84;
			reg _GEN_85;
			reg _GEN_86;
			reg _GEN_87;
			reg _GEN_88;
			reg _GEN_89;
			reg _GEN_90;
			reg _GEN_91;
			reg _GEN_92;
			reg _GEN_93;
			reg _GEN_94;
			_GEN_77 = io_mispredict_rob_idx - io_rob_head_idx;
			_GEN_78 = io_flush | (io_flush_mispredict & ((4'h0 - io_rob_head_idx) > _GEN_77));
			_GEN_79 = io_flush | (io_flush_mispredict & ((4'h1 - io_rob_head_idx) > _GEN_77));
			_GEN_80 = io_flush | (io_flush_mispredict & ((4'h2 - io_rob_head_idx) > _GEN_77));
			_GEN_81 = io_flush | (io_flush_mispredict & ((4'h3 - io_rob_head_idx) > _GEN_77));
			_GEN_82 = io_flush | (io_flush_mispredict & ((4'h4 - io_rob_head_idx) > _GEN_77));
			_GEN_83 = io_flush | (io_flush_mispredict & ((4'h5 - io_rob_head_idx) > _GEN_77));
			_GEN_84 = io_flush | (io_flush_mispredict & ((4'h6 - io_rob_head_idx) > _GEN_77));
			_GEN_85 = io_flush | (io_flush_mispredict & ((4'h7 - io_rob_head_idx) > _GEN_77));
			_GEN_86 = io_flush | (io_flush_mispredict & ((4'h8 - io_rob_head_idx) > _GEN_77));
			_GEN_87 = io_flush | (io_flush_mispredict & ((4'h9 - io_rob_head_idx) > _GEN_77));
			_GEN_88 = io_flush | (io_flush_mispredict & ((4'ha - io_rob_head_idx) > _GEN_77));
			_GEN_89 = io_flush | (io_flush_mispredict & ((4'hb - io_rob_head_idx) > _GEN_77));
			_GEN_90 = io_flush | (io_flush_mispredict & ((4'hc - io_rob_head_idx) > _GEN_77));
			_GEN_91 = io_flush | (io_flush_mispredict & ((4'hd - io_rob_head_idx) > _GEN_77));
			_GEN_92 = io_flush | (io_flush_mispredict & ((4'he - io_rob_head_idx) > _GEN_77));
			_GEN_93 = io_flush | (io_flush_mispredict & ((4'hf - io_rob_head_idx) > _GEN_77));
			_GEN_94 = (io_dmem_req_ready & io_dmem_req_valid_0) & _GEN_2;
			_GEN_61 = _GEN_10 | sb_valid_0;
			_GEN_62 = _GEN_11 | sb_valid_1;
			_GEN_63 = _GEN_12 | sb_valid_2;
			_GEN_64 = _GEN_13 | sb_valid_3;
			_GEN_65 = _GEN_14 | sb_valid_4;
			_GEN_66 = _GEN_15 | sb_valid_5;
			_GEN_67 = _GEN_16 | sb_valid_6;
			_GEN_68 = _GEN_17 | sb_valid_7;
			_GEN_69 = _GEN_18 | sb_valid_8;
			_GEN_70 = _GEN_19 | sb_valid_9;
			_GEN_71 = _GEN_20 | sb_valid_10;
			_GEN_72 = _GEN_21 | sb_valid_11;
			_GEN_73 = _GEN_22 | sb_valid_12;
			_GEN_74 = _GEN_23 | sb_valid_13;
			_GEN_75 = _GEN_24 | sb_valid_14;
			_GEN_76 = _GEN_25 | sb_valid_15;
			sb_valid_0 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h0)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h0) | _GEN_78) & _GEN_61 : ~_GEN_78 & _GEN_61);
			sb_valid_1 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h1)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h1) | _GEN_79) & _GEN_62 : ~_GEN_79 & _GEN_62);
			sb_valid_2 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h2)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h2) | _GEN_80) & _GEN_63 : ~_GEN_80 & _GEN_63);
			sb_valid_3 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h3)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h3) | _GEN_81) & _GEN_64 : ~_GEN_81 & _GEN_64);
			sb_valid_4 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h4)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h4) | _GEN_82) & _GEN_65 : ~_GEN_82 & _GEN_65);
			sb_valid_5 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h5)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h5) | _GEN_83) & _GEN_66 : ~_GEN_83 & _GEN_66);
			sb_valid_6 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h6)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h6) | _GEN_84) & _GEN_67 : ~_GEN_84 & _GEN_67);
			sb_valid_7 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h7)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h7) | _GEN_85) & _GEN_68 : ~_GEN_85 & _GEN_68);
			sb_valid_8 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h8)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h8) | _GEN_86) & _GEN_69 : ~_GEN_86 & _GEN_69);
			sb_valid_9 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'h9)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'h9) | _GEN_87) & _GEN_70 : ~_GEN_87 & _GEN_70);
			sb_valid_10 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'ha)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'ha) | _GEN_88) & _GEN_71 : ~_GEN_88 & _GEN_71);
			sb_valid_11 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'hb)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'hb) | _GEN_89) & _GEN_72 : ~_GEN_89 & _GEN_72);
			sb_valid_12 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'hc)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'hc) | _GEN_90) & _GEN_73 : ~_GEN_90 & _GEN_73);
			sb_valid_13 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'hd)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'hd) | _GEN_91) & _GEN_74 : ~_GEN_91 & _GEN_74);
			sb_valid_14 <= ~(io_commit_store_1_valid & (io_commit_store_1_bits == 4'he)) & (io_commit_store_0_valid ? ~((io_commit_store_0_bits == 4'he) | _GEN_92) & _GEN_75 : ~_GEN_92 & _GEN_75);
			sb_valid_15 <= ~(io_commit_store_1_valid & (&io_commit_store_1_bits)) & (io_commit_store_0_valid ? ~(&io_commit_store_0_bits | _GEN_93) & _GEN_76 : ~_GEN_93 & _GEN_76);
			c_sq_val_0 <= ~(_GEN_94 & (c_sq_head == 4'h0)) & (io_commit_store_1_valid ? (_GEN_45 | _GEN_27) | c_sq_val_0 : _GEN_27 | c_sq_val_0);
			c_sq_val_1 <= ~(_GEN_94 & (c_sq_head == 4'h1)) & (io_commit_store_1_valid ? (_GEN_46 | _GEN_28) | c_sq_val_1 : _GEN_28 | c_sq_val_1);
			c_sq_val_2 <= ~(_GEN_94 & (c_sq_head == 4'h2)) & (io_commit_store_1_valid ? (_GEN_47 | _GEN_29) | c_sq_val_2 : _GEN_29 | c_sq_val_2);
			c_sq_val_3 <= ~(_GEN_94 & (c_sq_head == 4'h3)) & (io_commit_store_1_valid ? (_GEN_48 | _GEN_30) | c_sq_val_3 : _GEN_30 | c_sq_val_3);
			c_sq_val_4 <= ~(_GEN_94 & (c_sq_head == 4'h4)) & (io_commit_store_1_valid ? (_GEN_49 | _GEN_31) | c_sq_val_4 : _GEN_31 | c_sq_val_4);
			c_sq_val_5 <= ~(_GEN_94 & (c_sq_head == 4'h5)) & (io_commit_store_1_valid ? (_GEN_50 | _GEN_32) | c_sq_val_5 : _GEN_32 | c_sq_val_5);
			c_sq_val_6 <= ~(_GEN_94 & (c_sq_head == 4'h6)) & (io_commit_store_1_valid ? (_GEN_51 | _GEN_33) | c_sq_val_6 : _GEN_33 | c_sq_val_6);
			c_sq_val_7 <= ~(_GEN_94 & (c_sq_head == 4'h7)) & (io_commit_store_1_valid ? (_GEN_52 | _GEN_34) | c_sq_val_7 : _GEN_34 | c_sq_val_7);
			c_sq_val_8 <= ~(_GEN_94 & (c_sq_head == 4'h8)) & (io_commit_store_1_valid ? (_GEN_53 | _GEN_35) | c_sq_val_8 : _GEN_35 | c_sq_val_8);
			c_sq_val_9 <= ~(_GEN_94 & (c_sq_head == 4'h9)) & (io_commit_store_1_valid ? (_GEN_54 | _GEN_36) | c_sq_val_9 : _GEN_36 | c_sq_val_9);
			c_sq_val_10 <= ~(_GEN_94 & (c_sq_head == 4'ha)) & (io_commit_store_1_valid ? (_GEN_55 | _GEN_37) | c_sq_val_10 : _GEN_37 | c_sq_val_10);
			c_sq_val_11 <= ~(_GEN_94 & (c_sq_head == 4'hb)) & (io_commit_store_1_valid ? (_GEN_56 | _GEN_38) | c_sq_val_11 : _GEN_38 | c_sq_val_11);
			c_sq_val_12 <= ~(_GEN_94 & (c_sq_head == 4'hc)) & (io_commit_store_1_valid ? (_GEN_57 | _GEN_39) | c_sq_val_12 : _GEN_39 | c_sq_val_12);
			c_sq_val_13 <= ~(_GEN_94 & (c_sq_head == 4'hd)) & (io_commit_store_1_valid ? (_GEN_58 | _GEN_40) | c_sq_val_13 : _GEN_40 | c_sq_val_13);
			c_sq_val_14 <= ~(_GEN_94 & (c_sq_head == 4'he)) & (io_commit_store_1_valid ? (_GEN_59 | _GEN_41) | c_sq_val_14 : _GEN_41 | c_sq_val_14);
			c_sq_val_15 <= ~(_GEN_94 & (&c_sq_head)) & (io_commit_store_1_valid ? (&t_idx | _GEN_42) | c_sq_val_15 : _GEN_42 | c_sq_val_15);
			if (_GEN_94)
				c_sq_head <= c_sq_head + 4'h1;
			c_sq_tail <= (c_sq_tail + {3'h0, io_commit_store_0_valid}) + {3'h0, io_commit_store_1_valid};
			state <= _GEN_60 | (~_GEN_3 & state);
		end
	end
	assign io_req_ready = io_req_ready_0;
	assign io_cdb_valid = _GEN_0 | _GEN_3;
	assign io_cdb_bits_rob_idx = (_GEN_0 ? io_req_bits_uop_rob_idx : (_GEN_3 ? load_uop_reg_rob_idx : 4'h0));
	assign io_cdb_bits_p_rd = (_GEN_8 ? 6'h00 : load_uop_reg_p_rd);
	assign io_cdb_bits_data = (_GEN_8 ? 64'h0000000000000000 : _GEN_7[load_uop_reg_mem_size * 64+:64]);
	assign io_cdb_bits_exc = (_GEN_0 ? io_req_bits_uop_exception : _GEN_3 & load_uop_reg_exception);
	assign io_dmem_req_valid = io_dmem_req_valid_0;
	assign io_dmem_req_bits_addr = (do_load_req ? _effective_addr_T : _GEN_4[c_sq_head * 64+:64]);
	assign io_dmem_req_bits_data = _GEN_5[c_sq_head * 64+:64];
	assign io_dmem_req_bits_cmd = {1'h0, (do_load_req ? 2'h1 : 2'h2)};
	assign io_dmem_req_bits_size = (do_load_req ? io_req_bits_uop_mem_size : _GEN_6[c_sq_head * 2+:2]);
endmodule
module BackEndTOP (
	clock,
	reset,
	io_from_frontend_ready,
	io_from_frontend_valid,
	io_from_frontend_bits_0_inst,
	io_from_frontend_bits_0_pc,
	io_from_frontend_bits_0_valid,
	io_from_frontend_bits_0_pred_taken,
	io_from_frontend_bits_0_pred_target,
	io_from_frontend_bits_1_inst,
	io_from_frontend_bits_1_pc,
	io_from_frontend_bits_1_valid,
	io_from_frontend_bits_1_pred_taken,
	io_from_frontend_bits_1_pred_target,
	io_redirect_valid,
	io_redirect_pc,
	io_commit_num,
	io_dmem_req_ready,
	io_dmem_req_valid,
	io_dmem_req_bits_addr,
	io_dmem_req_bits_data,
	io_dmem_req_bits_cmd,
	io_dmem_req_bits_size,
	io_dmem_resp_valid,
	io_dmem_resp_bits_data,
	io_bpu_update_valid,
	io_bpu_update_bits_pc,
	io_bpu_update_bits_target,
	io_bpu_update_bits_taken
);
	input clock;
	input reset;
	output wire io_from_frontend_ready;
	input io_from_frontend_valid;
	input [31:0] io_from_frontend_bits_0_inst;
	input [63:0] io_from_frontend_bits_0_pc;
	input io_from_frontend_bits_0_valid;
	input io_from_frontend_bits_0_pred_taken;
	input [63:0] io_from_frontend_bits_0_pred_target;
	input [31:0] io_from_frontend_bits_1_inst;
	input [63:0] io_from_frontend_bits_1_pc;
	input io_from_frontend_bits_1_valid;
	input io_from_frontend_bits_1_pred_taken;
	input [63:0] io_from_frontend_bits_1_pred_target;
	output wire io_redirect_valid;
	output wire [63:0] io_redirect_pc;
	output wire [1:0] io_commit_num;
	input io_dmem_req_ready;
	output wire io_dmem_req_valid;
	output wire [63:0] io_dmem_req_bits_addr;
	output wire [63:0] io_dmem_req_bits_data;
	output wire [2:0] io_dmem_req_bits_cmd;
	output wire [1:0] io_dmem_req_bits_size;
	input io_dmem_resp_valid;
	input [63:0] io_dmem_resp_bits_data;
	output wire io_bpu_update_valid;
	output wire [63:0] io_bpu_update_bits_pc;
	output wire [63:0] io_bpu_update_bits_target;
	output wire io_bpu_update_bits_taken;
	wire _lsu_io_req_ready;
	wire _lsu_io_cdb_valid;
	wire [3:0] _lsu_io_cdb_bits_rob_idx;
	wire [5:0] _lsu_io_cdb_bits_p_rd;
	wire [63:0] _lsu_io_cdb_bits_data;
	wire _lsu_io_cdb_bits_exc;
	wire _alu_io_cdb_valid;
	wire [3:0] _alu_io_cdb_bits_rob_idx;
	wire [5:0] _alu_io_cdb_bits_p_rd;
	wire [63:0] _alu_io_cdb_bits_data;
	wire _alu_io_cdb_bits_exc;
	wire _alu_io_cdb_bits_is_branch;
	wire _alu_io_cdb_bits_br_taken;
	wire [63:0] _alu_io_cdb_bits_br_target;
	wire [63:0] _alu_io_cdb_bits_br_pc;
	wire _alu_io_br_redirect;
	wire [63:0] _alu_io_br_redirect_pc;
	wire _alu_io_br_res_valid;
	wire _alu_io_br_res_bits_mispredicted;
	wire [3:0] _alu_io_br_res_bits_rob_idx;
	wire [63:0] _prf_io_alu_resp_rs1;
	wire [63:0] _prf_io_alu_resp_rs2;
	wire [63:0] _prf_io_lsu_resp_rs1;
	wire [63:0] _prf_io_lsu_resp_rs2;
	wire _regread_io_iss_alu_ready;
	wire _regread_io_iss_lsu_ready;
	wire _regread_io_exe_alu_valid;
	wire [63:0] _regread_io_exe_alu_bits_uop_pc;
	wire [9:0] _regread_io_exe_alu_bits_uop_alu_op;
	wire [1:0] _regread_io_exe_alu_bits_uop_op1_sel;
	wire [2:0] _regread_io_exe_alu_bits_uop_op2_sel;
	wire [63:0] _regread_io_exe_alu_bits_uop_imm;
	wire _regread_io_exe_alu_bits_uop_is_w;
	wire [3:0] _regread_io_exe_alu_bits_uop_br_type;
	wire [5:0] _regread_io_exe_alu_bits_uop_p_rd;
	wire [3:0] _regread_io_exe_alu_bits_uop_rob_idx;
	wire _regread_io_exe_alu_bits_uop_exception;
	wire _regread_io_exe_alu_bits_uop_pred_taken;
	wire [63:0] _regread_io_exe_alu_bits_uop_pred_target;
	wire [63:0] _regread_io_exe_alu_bits_rs1_data;
	wire [63:0] _regread_io_exe_alu_bits_rs2_data;
	wire _regread_io_exe_lsu_valid;
	wire [63:0] _regread_io_exe_lsu_bits_uop_imm;
	wire [2:0] _regread_io_exe_lsu_bits_uop_mem_cmd;
	wire [1:0] _regread_io_exe_lsu_bits_uop_mem_size;
	wire _regread_io_exe_lsu_bits_uop_mem_signed;
	wire [5:0] _regread_io_exe_lsu_bits_uop_p_rd;
	wire [3:0] _regread_io_exe_lsu_bits_uop_rob_idx;
	wire _regread_io_exe_lsu_bits_uop_exception;
	wire [63:0] _regread_io_exe_lsu_bits_rs1_data;
	wire [63:0] _regread_io_exe_lsu_bits_rs2_data;
	wire [5:0] _regread_io_prf_alu_req_rs1;
	wire [5:0] _regread_io_prf_alu_req_rs2;
	wire [5:0] _regread_io_prf_lsu_req_rs1;
	wire [5:0] _regread_io_prf_lsu_req_rs2;
	wire _issue_io_enq_ready;
	wire _issue_io_iss_alu_valid;
	wire _issue_io_iss_alu_bits_valid;
	wire [63:0] _issue_io_iss_alu_bits_pc;
	wire [31:0] _issue_io_iss_alu_bits_inst;
	wire [5:0] _issue_io_iss_alu_bits_fu_code;
	wire [9:0] _issue_io_iss_alu_bits_alu_op;
	wire [1:0] _issue_io_iss_alu_bits_op1_sel;
	wire [2:0] _issue_io_iss_alu_bits_op2_sel;
	wire [63:0] _issue_io_iss_alu_bits_imm;
	wire [2:0] _issue_io_iss_alu_bits_imm_sel;
	wire _issue_io_iss_alu_bits_is_w;
	wire [2:0] _issue_io_iss_alu_bits_mem_cmd;
	wire [1:0] _issue_io_iss_alu_bits_mem_size;
	wire _issue_io_iss_alu_bits_mem_signed;
	wire [3:0] _issue_io_iss_alu_bits_br_type;
	wire [4:0] _issue_io_iss_alu_bits_l_rd;
	wire [4:0] _issue_io_iss_alu_bits_l_rs1;
	wire [4:0] _issue_io_iss_alu_bits_l_rs2;
	wire _issue_io_iss_alu_bits_rf_wen;
	wire _issue_io_iss_alu_bits_use_rs1;
	wire _issue_io_iss_alu_bits_use_rs2;
	wire [5:0] _issue_io_iss_alu_bits_p_rd;
	wire [5:0] _issue_io_iss_alu_bits_p_rs1;
	wire [5:0] _issue_io_iss_alu_bits_p_rs2;
	wire _issue_io_iss_alu_bits_prs1_ready;
	wire _issue_io_iss_alu_bits_prs2_ready;
	wire [5:0] _issue_io_iss_alu_bits_stale_p_rd;
	wire [3:0] _issue_io_iss_alu_bits_rob_idx;
	wire _issue_io_iss_alu_bits_exception;
	wire _issue_io_iss_alu_bits_pred_taken;
	wire [63:0] _issue_io_iss_alu_bits_pred_target;
	wire _issue_io_iss_lsu_valid;
	wire _issue_io_iss_lsu_bits_valid;
	wire [63:0] _issue_io_iss_lsu_bits_pc;
	wire [31:0] _issue_io_iss_lsu_bits_inst;
	wire [5:0] _issue_io_iss_lsu_bits_fu_code;
	wire [9:0] _issue_io_iss_lsu_bits_alu_op;
	wire [1:0] _issue_io_iss_lsu_bits_op1_sel;
	wire [2:0] _issue_io_iss_lsu_bits_op2_sel;
	wire [63:0] _issue_io_iss_lsu_bits_imm;
	wire [2:0] _issue_io_iss_lsu_bits_imm_sel;
	wire _issue_io_iss_lsu_bits_is_w;
	wire [2:0] _issue_io_iss_lsu_bits_mem_cmd;
	wire [1:0] _issue_io_iss_lsu_bits_mem_size;
	wire _issue_io_iss_lsu_bits_mem_signed;
	wire [3:0] _issue_io_iss_lsu_bits_br_type;
	wire [4:0] _issue_io_iss_lsu_bits_l_rd;
	wire [4:0] _issue_io_iss_lsu_bits_l_rs1;
	wire [4:0] _issue_io_iss_lsu_bits_l_rs2;
	wire _issue_io_iss_lsu_bits_rf_wen;
	wire _issue_io_iss_lsu_bits_use_rs1;
	wire _issue_io_iss_lsu_bits_use_rs2;
	wire [5:0] _issue_io_iss_lsu_bits_p_rd;
	wire [5:0] _issue_io_iss_lsu_bits_p_rs1;
	wire [5:0] _issue_io_iss_lsu_bits_p_rs2;
	wire _issue_io_iss_lsu_bits_prs1_ready;
	wire _issue_io_iss_lsu_bits_prs2_ready;
	wire [5:0] _issue_io_iss_lsu_bits_stale_p_rd;
	wire [3:0] _issue_io_iss_lsu_bits_rob_idx;
	wire _issue_io_iss_lsu_bits_exception;
	wire _issue_io_iss_lsu_bits_pred_taken;
	wire [63:0] _issue_io_iss_lsu_bits_pred_target;
	wire _rob_io_enq_ready;
	wire [3:0] _rob_io_rob_idx_alloc_0;
	wire [3:0] _rob_io_rob_idx_alloc_1;
	wire _rob_io_commit_free_0_valid;
	wire [5:0] _rob_io_commit_free_0_bits;
	wire _rob_io_commit_free_1_valid;
	wire [5:0] _rob_io_commit_free_1_bits;
	wire _rob_io_flush_pipeline;
	wire _rob_io_commit_store_0_valid;
	wire [3:0] _rob_io_commit_store_0_bits;
	wire _rob_io_commit_store_1_valid;
	wire [3:0] _rob_io_commit_store_1_bits;
	wire _rob_io_rbk_active;
	wire _rob_io_rbk_valid;
	wire [4:0] _rob_io_rbk_l_rd;
	wire [5:0] _rob_io_rbk_p_rd;
	wire [5:0] _rob_io_rbk_stale_p_rd;
	wire [3:0] _rob_io_rob_head_idx;
	wire _rename_io_enq_ready;
	wire _rename_io_deq_valid;
	wire _rename_io_deq_bits_0_valid;
	wire [63:0] _rename_io_deq_bits_0_pc;
	wire [31:0] _rename_io_deq_bits_0_inst;
	wire [5:0] _rename_io_deq_bits_0_fu_code;
	wire [9:0] _rename_io_deq_bits_0_alu_op;
	wire [1:0] _rename_io_deq_bits_0_op1_sel;
	wire [2:0] _rename_io_deq_bits_0_op2_sel;
	wire [63:0] _rename_io_deq_bits_0_imm;
	wire [2:0] _rename_io_deq_bits_0_imm_sel;
	wire _rename_io_deq_bits_0_is_w;
	wire [2:0] _rename_io_deq_bits_0_mem_cmd;
	wire [1:0] _rename_io_deq_bits_0_mem_size;
	wire _rename_io_deq_bits_0_mem_signed;
	wire [3:0] _rename_io_deq_bits_0_br_type;
	wire [4:0] _rename_io_deq_bits_0_l_rd;
	wire [4:0] _rename_io_deq_bits_0_l_rs1;
	wire [4:0] _rename_io_deq_bits_0_l_rs2;
	wire _rename_io_deq_bits_0_rf_wen;
	wire _rename_io_deq_bits_0_use_rs1;
	wire _rename_io_deq_bits_0_use_rs2;
	wire [5:0] _rename_io_deq_bits_0_p_rd;
	wire [5:0] _rename_io_deq_bits_0_p_rs1;
	wire [5:0] _rename_io_deq_bits_0_p_rs2;
	wire _rename_io_deq_bits_0_prs1_ready;
	wire _rename_io_deq_bits_0_prs2_ready;
	wire [5:0] _rename_io_deq_bits_0_stale_p_rd;
	wire _rename_io_deq_bits_0_exception;
	wire _rename_io_deq_bits_0_pred_taken;
	wire [63:0] _rename_io_deq_bits_0_pred_target;
	wire _rename_io_deq_bits_1_valid;
	wire [63:0] _rename_io_deq_bits_1_pc;
	wire [31:0] _rename_io_deq_bits_1_inst;
	wire [5:0] _rename_io_deq_bits_1_fu_code;
	wire [9:0] _rename_io_deq_bits_1_alu_op;
	wire [1:0] _rename_io_deq_bits_1_op1_sel;
	wire [2:0] _rename_io_deq_bits_1_op2_sel;
	wire [63:0] _rename_io_deq_bits_1_imm;
	wire [2:0] _rename_io_deq_bits_1_imm_sel;
	wire _rename_io_deq_bits_1_is_w;
	wire [2:0] _rename_io_deq_bits_1_mem_cmd;
	wire [1:0] _rename_io_deq_bits_1_mem_size;
	wire _rename_io_deq_bits_1_mem_signed;
	wire [3:0] _rename_io_deq_bits_1_br_type;
	wire [4:0] _rename_io_deq_bits_1_l_rd;
	wire [4:0] _rename_io_deq_bits_1_l_rs1;
	wire [4:0] _rename_io_deq_bits_1_l_rs2;
	wire _rename_io_deq_bits_1_rf_wen;
	wire _rename_io_deq_bits_1_use_rs1;
	wire _rename_io_deq_bits_1_use_rs2;
	wire [5:0] _rename_io_deq_bits_1_p_rd;
	wire [5:0] _rename_io_deq_bits_1_p_rs1;
	wire [5:0] _rename_io_deq_bits_1_p_rs2;
	wire _rename_io_deq_bits_1_prs1_ready;
	wire _rename_io_deq_bits_1_prs2_ready;
	wire [5:0] _rename_io_deq_bits_1_stale_p_rd;
	wire _rename_io_deq_bits_1_exception;
	wire _rename_io_deq_bits_1_pred_taken;
	wire [63:0] _rename_io_deq_bits_1_pred_target;
	wire _decode_io_deq_valid;
	wire _decode_io_deq_bits_0_valid;
	wire [63:0] _decode_io_deq_bits_0_pc;
	wire [31:0] _decode_io_deq_bits_0_inst;
	wire [5:0] _decode_io_deq_bits_0_fu_code;
	wire [9:0] _decode_io_deq_bits_0_alu_op;
	wire [1:0] _decode_io_deq_bits_0_op1_sel;
	wire [2:0] _decode_io_deq_bits_0_op2_sel;
	wire [63:0] _decode_io_deq_bits_0_imm;
	wire [2:0] _decode_io_deq_bits_0_imm_sel;
	wire _decode_io_deq_bits_0_is_w;
	wire [2:0] _decode_io_deq_bits_0_mem_cmd;
	wire [1:0] _decode_io_deq_bits_0_mem_size;
	wire _decode_io_deq_bits_0_mem_signed;
	wire [3:0] _decode_io_deq_bits_0_br_type;
	wire [4:0] _decode_io_deq_bits_0_l_rd;
	wire [4:0] _decode_io_deq_bits_0_l_rs1;
	wire [4:0] _decode_io_deq_bits_0_l_rs2;
	wire _decode_io_deq_bits_0_rf_wen;
	wire _decode_io_deq_bits_0_use_rs1;
	wire _decode_io_deq_bits_0_use_rs2;
	wire _decode_io_deq_bits_0_exception;
	wire _decode_io_deq_bits_0_pred_taken;
	wire [63:0] _decode_io_deq_bits_0_pred_target;
	wire _decode_io_deq_bits_1_valid;
	wire [63:0] _decode_io_deq_bits_1_pc;
	wire [31:0] _decode_io_deq_bits_1_inst;
	wire [5:0] _decode_io_deq_bits_1_fu_code;
	wire [9:0] _decode_io_deq_bits_1_alu_op;
	wire [1:0] _decode_io_deq_bits_1_op1_sel;
	wire [2:0] _decode_io_deq_bits_1_op2_sel;
	wire [63:0] _decode_io_deq_bits_1_imm;
	wire [2:0] _decode_io_deq_bits_1_imm_sel;
	wire _decode_io_deq_bits_1_is_w;
	wire [2:0] _decode_io_deq_bits_1_mem_cmd;
	wire [1:0] _decode_io_deq_bits_1_mem_size;
	wire _decode_io_deq_bits_1_mem_signed;
	wire [3:0] _decode_io_deq_bits_1_br_type;
	wire [4:0] _decode_io_deq_bits_1_l_rd;
	wire [4:0] _decode_io_deq_bits_1_l_rs1;
	wire [4:0] _decode_io_deq_bits_1_l_rs2;
	wire _decode_io_deq_bits_1_rf_wen;
	wire _decode_io_deq_bits_1_use_rs1;
	wire _decode_io_deq_bits_1_use_rs2;
	wire _decode_io_deq_bits_1_exception;
	wire _decode_io_deq_bits_1_pred_taken;
	wire [63:0] _decode_io_deq_bits_1_pred_target;
	wire dispatch_ready = _rob_io_enq_ready & _issue_io_enq_ready;
	wire dispatch_fire = _rename_io_deq_valid & dispatch_ready;
	wire _issue_io_flush_mispredict_T = _alu_io_br_res_bits_mispredicted & _alu_io_br_res_valid;
	DecodeUnit decode(
		.io_enq_ready(io_from_frontend_ready),
		.io_enq_valid(io_from_frontend_valid),
		.io_enq_bits_0_inst(io_from_frontend_bits_0_inst),
		.io_enq_bits_0_pc(io_from_frontend_bits_0_pc),
		.io_enq_bits_0_valid(io_from_frontend_bits_0_valid),
		.io_enq_bits_0_pred_taken(io_from_frontend_bits_0_pred_taken),
		.io_enq_bits_0_pred_target(io_from_frontend_bits_0_pred_target),
		.io_enq_bits_1_inst(io_from_frontend_bits_1_inst),
		.io_enq_bits_1_pc(io_from_frontend_bits_1_pc),
		.io_enq_bits_1_valid(io_from_frontend_bits_1_valid),
		.io_enq_bits_1_pred_taken(io_from_frontend_bits_1_pred_taken),
		.io_enq_bits_1_pred_target(io_from_frontend_bits_1_pred_target),
		.io_deq_ready(_rename_io_enq_ready),
		.io_deq_valid(_decode_io_deq_valid),
		.io_deq_bits_0_valid(_decode_io_deq_bits_0_valid),
		.io_deq_bits_0_pc(_decode_io_deq_bits_0_pc),
		.io_deq_bits_0_inst(_decode_io_deq_bits_0_inst),
		.io_deq_bits_0_fu_code(_decode_io_deq_bits_0_fu_code),
		.io_deq_bits_0_alu_op(_decode_io_deq_bits_0_alu_op),
		.io_deq_bits_0_op1_sel(_decode_io_deq_bits_0_op1_sel),
		.io_deq_bits_0_op2_sel(_decode_io_deq_bits_0_op2_sel),
		.io_deq_bits_0_imm(_decode_io_deq_bits_0_imm),
		.io_deq_bits_0_imm_sel(_decode_io_deq_bits_0_imm_sel),
		.io_deq_bits_0_is_w(_decode_io_deq_bits_0_is_w),
		.io_deq_bits_0_mem_cmd(_decode_io_deq_bits_0_mem_cmd),
		.io_deq_bits_0_mem_size(_decode_io_deq_bits_0_mem_size),
		.io_deq_bits_0_mem_signed(_decode_io_deq_bits_0_mem_signed),
		.io_deq_bits_0_br_type(_decode_io_deq_bits_0_br_type),
		.io_deq_bits_0_l_rd(_decode_io_deq_bits_0_l_rd),
		.io_deq_bits_0_l_rs1(_decode_io_deq_bits_0_l_rs1),
		.io_deq_bits_0_l_rs2(_decode_io_deq_bits_0_l_rs2),
		.io_deq_bits_0_rf_wen(_decode_io_deq_bits_0_rf_wen),
		.io_deq_bits_0_use_rs1(_decode_io_deq_bits_0_use_rs1),
		.io_deq_bits_0_use_rs2(_decode_io_deq_bits_0_use_rs2),
		.io_deq_bits_0_exception(_decode_io_deq_bits_0_exception),
		.io_deq_bits_0_pred_taken(_decode_io_deq_bits_0_pred_taken),
		.io_deq_bits_0_pred_target(_decode_io_deq_bits_0_pred_target),
		.io_deq_bits_1_valid(_decode_io_deq_bits_1_valid),
		.io_deq_bits_1_pc(_decode_io_deq_bits_1_pc),
		.io_deq_bits_1_inst(_decode_io_deq_bits_1_inst),
		.io_deq_bits_1_fu_code(_decode_io_deq_bits_1_fu_code),
		.io_deq_bits_1_alu_op(_decode_io_deq_bits_1_alu_op),
		.io_deq_bits_1_op1_sel(_decode_io_deq_bits_1_op1_sel),
		.io_deq_bits_1_op2_sel(_decode_io_deq_bits_1_op2_sel),
		.io_deq_bits_1_imm(_decode_io_deq_bits_1_imm),
		.io_deq_bits_1_imm_sel(_decode_io_deq_bits_1_imm_sel),
		.io_deq_bits_1_is_w(_decode_io_deq_bits_1_is_w),
		.io_deq_bits_1_mem_cmd(_decode_io_deq_bits_1_mem_cmd),
		.io_deq_bits_1_mem_size(_decode_io_deq_bits_1_mem_size),
		.io_deq_bits_1_mem_signed(_decode_io_deq_bits_1_mem_signed),
		.io_deq_bits_1_br_type(_decode_io_deq_bits_1_br_type),
		.io_deq_bits_1_l_rd(_decode_io_deq_bits_1_l_rd),
		.io_deq_bits_1_l_rs1(_decode_io_deq_bits_1_l_rs1),
		.io_deq_bits_1_l_rs2(_decode_io_deq_bits_1_l_rs2),
		.io_deq_bits_1_rf_wen(_decode_io_deq_bits_1_rf_wen),
		.io_deq_bits_1_use_rs1(_decode_io_deq_bits_1_use_rs1),
		.io_deq_bits_1_use_rs2(_decode_io_deq_bits_1_use_rs2),
		.io_deq_bits_1_exception(_decode_io_deq_bits_1_exception),
		.io_deq_bits_1_pred_taken(_decode_io_deq_bits_1_pred_taken),
		.io_deq_bits_1_pred_target(_decode_io_deq_bits_1_pred_target)
	);
	RenameUnit rename(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_rename_io_enq_ready),
		.io_enq_valid(_decode_io_deq_valid),
		.io_enq_bits_0_valid(_decode_io_deq_bits_0_valid),
		.io_enq_bits_0_pc(_decode_io_deq_bits_0_pc),
		.io_enq_bits_0_inst(_decode_io_deq_bits_0_inst),
		.io_enq_bits_0_fu_code(_decode_io_deq_bits_0_fu_code),
		.io_enq_bits_0_alu_op(_decode_io_deq_bits_0_alu_op),
		.io_enq_bits_0_op1_sel(_decode_io_deq_bits_0_op1_sel),
		.io_enq_bits_0_op2_sel(_decode_io_deq_bits_0_op2_sel),
		.io_enq_bits_0_imm(_decode_io_deq_bits_0_imm),
		.io_enq_bits_0_imm_sel(_decode_io_deq_bits_0_imm_sel),
		.io_enq_bits_0_is_w(_decode_io_deq_bits_0_is_w),
		.io_enq_bits_0_mem_cmd(_decode_io_deq_bits_0_mem_cmd),
		.io_enq_bits_0_mem_size(_decode_io_deq_bits_0_mem_size),
		.io_enq_bits_0_mem_signed(_decode_io_deq_bits_0_mem_signed),
		.io_enq_bits_0_br_type(_decode_io_deq_bits_0_br_type),
		.io_enq_bits_0_l_rd(_decode_io_deq_bits_0_l_rd),
		.io_enq_bits_0_l_rs1(_decode_io_deq_bits_0_l_rs1),
		.io_enq_bits_0_l_rs2(_decode_io_deq_bits_0_l_rs2),
		.io_enq_bits_0_rf_wen(_decode_io_deq_bits_0_rf_wen),
		.io_enq_bits_0_use_rs1(_decode_io_deq_bits_0_use_rs1),
		.io_enq_bits_0_use_rs2(_decode_io_deq_bits_0_use_rs2),
		.io_enq_bits_0_exception(_decode_io_deq_bits_0_exception),
		.io_enq_bits_0_pred_taken(_decode_io_deq_bits_0_pred_taken),
		.io_enq_bits_0_pred_target(_decode_io_deq_bits_0_pred_target),
		.io_enq_bits_1_valid(_decode_io_deq_bits_1_valid),
		.io_enq_bits_1_pc(_decode_io_deq_bits_1_pc),
		.io_enq_bits_1_inst(_decode_io_deq_bits_1_inst),
		.io_enq_bits_1_fu_code(_decode_io_deq_bits_1_fu_code),
		.io_enq_bits_1_alu_op(_decode_io_deq_bits_1_alu_op),
		.io_enq_bits_1_op1_sel(_decode_io_deq_bits_1_op1_sel),
		.io_enq_bits_1_op2_sel(_decode_io_deq_bits_1_op2_sel),
		.io_enq_bits_1_imm(_decode_io_deq_bits_1_imm),
		.io_enq_bits_1_imm_sel(_decode_io_deq_bits_1_imm_sel),
		.io_enq_bits_1_is_w(_decode_io_deq_bits_1_is_w),
		.io_enq_bits_1_mem_cmd(_decode_io_deq_bits_1_mem_cmd),
		.io_enq_bits_1_mem_size(_decode_io_deq_bits_1_mem_size),
		.io_enq_bits_1_mem_signed(_decode_io_deq_bits_1_mem_signed),
		.io_enq_bits_1_br_type(_decode_io_deq_bits_1_br_type),
		.io_enq_bits_1_l_rd(_decode_io_deq_bits_1_l_rd),
		.io_enq_bits_1_l_rs1(_decode_io_deq_bits_1_l_rs1),
		.io_enq_bits_1_l_rs2(_decode_io_deq_bits_1_l_rs2),
		.io_enq_bits_1_rf_wen(_decode_io_deq_bits_1_rf_wen),
		.io_enq_bits_1_use_rs1(_decode_io_deq_bits_1_use_rs1),
		.io_enq_bits_1_use_rs2(_decode_io_deq_bits_1_use_rs2),
		.io_enq_bits_1_exception(_decode_io_deq_bits_1_exception),
		.io_enq_bits_1_pred_taken(_decode_io_deq_bits_1_pred_taken),
		.io_enq_bits_1_pred_target(_decode_io_deq_bits_1_pred_target),
		.io_deq_ready(dispatch_ready),
		.io_deq_valid(_rename_io_deq_valid),
		.io_deq_bits_0_valid(_rename_io_deq_bits_0_valid),
		.io_deq_bits_0_pc(_rename_io_deq_bits_0_pc),
		.io_deq_bits_0_inst(_rename_io_deq_bits_0_inst),
		.io_deq_bits_0_fu_code(_rename_io_deq_bits_0_fu_code),
		.io_deq_bits_0_alu_op(_rename_io_deq_bits_0_alu_op),
		.io_deq_bits_0_op1_sel(_rename_io_deq_bits_0_op1_sel),
		.io_deq_bits_0_op2_sel(_rename_io_deq_bits_0_op2_sel),
		.io_deq_bits_0_imm(_rename_io_deq_bits_0_imm),
		.io_deq_bits_0_imm_sel(_rename_io_deq_bits_0_imm_sel),
		.io_deq_bits_0_is_w(_rename_io_deq_bits_0_is_w),
		.io_deq_bits_0_mem_cmd(_rename_io_deq_bits_0_mem_cmd),
		.io_deq_bits_0_mem_size(_rename_io_deq_bits_0_mem_size),
		.io_deq_bits_0_mem_signed(_rename_io_deq_bits_0_mem_signed),
		.io_deq_bits_0_br_type(_rename_io_deq_bits_0_br_type),
		.io_deq_bits_0_l_rd(_rename_io_deq_bits_0_l_rd),
		.io_deq_bits_0_l_rs1(_rename_io_deq_bits_0_l_rs1),
		.io_deq_bits_0_l_rs2(_rename_io_deq_bits_0_l_rs2),
		.io_deq_bits_0_rf_wen(_rename_io_deq_bits_0_rf_wen),
		.io_deq_bits_0_use_rs1(_rename_io_deq_bits_0_use_rs1),
		.io_deq_bits_0_use_rs2(_rename_io_deq_bits_0_use_rs2),
		.io_deq_bits_0_p_rd(_rename_io_deq_bits_0_p_rd),
		.io_deq_bits_0_p_rs1(_rename_io_deq_bits_0_p_rs1),
		.io_deq_bits_0_p_rs2(_rename_io_deq_bits_0_p_rs2),
		.io_deq_bits_0_prs1_ready(_rename_io_deq_bits_0_prs1_ready),
		.io_deq_bits_0_prs2_ready(_rename_io_deq_bits_0_prs2_ready),
		.io_deq_bits_0_stale_p_rd(_rename_io_deq_bits_0_stale_p_rd),
		.io_deq_bits_0_exception(_rename_io_deq_bits_0_exception),
		.io_deq_bits_0_pred_taken(_rename_io_deq_bits_0_pred_taken),
		.io_deq_bits_0_pred_target(_rename_io_deq_bits_0_pred_target),
		.io_deq_bits_1_valid(_rename_io_deq_bits_1_valid),
		.io_deq_bits_1_pc(_rename_io_deq_bits_1_pc),
		.io_deq_bits_1_inst(_rename_io_deq_bits_1_inst),
		.io_deq_bits_1_fu_code(_rename_io_deq_bits_1_fu_code),
		.io_deq_bits_1_alu_op(_rename_io_deq_bits_1_alu_op),
		.io_deq_bits_1_op1_sel(_rename_io_deq_bits_1_op1_sel),
		.io_deq_bits_1_op2_sel(_rename_io_deq_bits_1_op2_sel),
		.io_deq_bits_1_imm(_rename_io_deq_bits_1_imm),
		.io_deq_bits_1_imm_sel(_rename_io_deq_bits_1_imm_sel),
		.io_deq_bits_1_is_w(_rename_io_deq_bits_1_is_w),
		.io_deq_bits_1_mem_cmd(_rename_io_deq_bits_1_mem_cmd),
		.io_deq_bits_1_mem_size(_rename_io_deq_bits_1_mem_size),
		.io_deq_bits_1_mem_signed(_rename_io_deq_bits_1_mem_signed),
		.io_deq_bits_1_br_type(_rename_io_deq_bits_1_br_type),
		.io_deq_bits_1_l_rd(_rename_io_deq_bits_1_l_rd),
		.io_deq_bits_1_l_rs1(_rename_io_deq_bits_1_l_rs1),
		.io_deq_bits_1_l_rs2(_rename_io_deq_bits_1_l_rs2),
		.io_deq_bits_1_rf_wen(_rename_io_deq_bits_1_rf_wen),
		.io_deq_bits_1_use_rs1(_rename_io_deq_bits_1_use_rs1),
		.io_deq_bits_1_use_rs2(_rename_io_deq_bits_1_use_rs2),
		.io_deq_bits_1_p_rd(_rename_io_deq_bits_1_p_rd),
		.io_deq_bits_1_p_rs1(_rename_io_deq_bits_1_p_rs1),
		.io_deq_bits_1_p_rs2(_rename_io_deq_bits_1_p_rs2),
		.io_deq_bits_1_prs1_ready(_rename_io_deq_bits_1_prs1_ready),
		.io_deq_bits_1_prs2_ready(_rename_io_deq_bits_1_prs2_ready),
		.io_deq_bits_1_stale_p_rd(_rename_io_deq_bits_1_stale_p_rd),
		.io_deq_bits_1_exception(_rename_io_deq_bits_1_exception),
		.io_deq_bits_1_pred_taken(_rename_io_deq_bits_1_pred_taken),
		.io_deq_bits_1_pred_target(_rename_io_deq_bits_1_pred_target),
		.io_commit_free_0_valid(_rob_io_commit_free_0_valid),
		.io_commit_free_0_bits(_rob_io_commit_free_0_bits),
		.io_commit_free_1_valid(_rob_io_commit_free_1_valid),
		.io_commit_free_1_bits(_rob_io_commit_free_1_bits),
		.io_cdb_0_valid(_alu_io_cdb_valid),
		.io_cdb_0_bits_p_rd(_alu_io_cdb_bits_p_rd),
		.io_cdb_1_valid(_lsu_io_cdb_valid),
		.io_cdb_1_bits_p_rd(_lsu_io_cdb_bits_p_rd),
		.io_rbk_active(_rob_io_rbk_active),
		.io_rbk_valid(_rob_io_rbk_valid),
		.io_rbk_l_rd(_rob_io_rbk_l_rd),
		.io_rbk_p_rd(_rob_io_rbk_p_rd),
		.io_rbk_stale_p_rd(_rob_io_rbk_stale_p_rd)
	);
	Rob rob(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_rob_io_enq_ready),
		.io_enq_valid(dispatch_fire),
		.io_enq_bits_0_valid(_rename_io_deq_bits_0_valid),
		.io_enq_bits_0_inst(_rename_io_deq_bits_0_inst),
		.io_enq_bits_0_mem_cmd(_rename_io_deq_bits_0_mem_cmd),
		.io_enq_bits_0_l_rd(_rename_io_deq_bits_0_l_rd),
		.io_enq_bits_0_rf_wen(_rename_io_deq_bits_0_rf_wen),
		.io_enq_bits_0_p_rd(_rename_io_deq_bits_0_p_rd),
		.io_enq_bits_0_stale_p_rd(_rename_io_deq_bits_0_stale_p_rd),
		.io_enq_bits_0_exception(_rename_io_deq_bits_0_exception),
		.io_enq_bits_1_valid(_rename_io_deq_bits_1_valid),
		.io_enq_bits_1_inst(_rename_io_deq_bits_1_inst),
		.io_enq_bits_1_mem_cmd(_rename_io_deq_bits_1_mem_cmd),
		.io_enq_bits_1_l_rd(_rename_io_deq_bits_1_l_rd),
		.io_enq_bits_1_rf_wen(_rename_io_deq_bits_1_rf_wen),
		.io_enq_bits_1_p_rd(_rename_io_deq_bits_1_p_rd),
		.io_enq_bits_1_stale_p_rd(_rename_io_deq_bits_1_stale_p_rd),
		.io_enq_bits_1_exception(_rename_io_deq_bits_1_exception),
		.io_rob_idx_alloc_0(_rob_io_rob_idx_alloc_0),
		.io_rob_idx_alloc_1(_rob_io_rob_idx_alloc_1),
		.io_cdb_0_valid(_alu_io_cdb_valid),
		.io_cdb_0_bits_rob_idx(_alu_io_cdb_bits_rob_idx),
		.io_cdb_0_bits_exc(_alu_io_cdb_bits_exc),
		.io_cdb_0_bits_is_branch(_alu_io_cdb_bits_is_branch),
		.io_cdb_0_bits_br_taken(_alu_io_cdb_bits_br_taken),
		.io_cdb_0_bits_br_target(_alu_io_cdb_bits_br_target),
		.io_cdb_0_bits_br_pc(_alu_io_cdb_bits_br_pc),
		.io_cdb_1_valid(_lsu_io_cdb_valid),
		.io_cdb_1_bits_rob_idx(_lsu_io_cdb_bits_rob_idx),
		.io_cdb_1_bits_exc(_lsu_io_cdb_bits_exc),
		.io_commit_free_0_valid(_rob_io_commit_free_0_valid),
		.io_commit_free_0_bits(_rob_io_commit_free_0_bits),
		.io_commit_free_1_valid(_rob_io_commit_free_1_valid),
		.io_commit_free_1_bits(_rob_io_commit_free_1_bits),
		.io_flush_pipeline(_rob_io_flush_pipeline),
		.io_commit_store_0_valid(_rob_io_commit_store_0_valid),
		.io_commit_store_0_bits(_rob_io_commit_store_0_bits),
		.io_commit_store_1_valid(_rob_io_commit_store_1_valid),
		.io_commit_store_1_bits(_rob_io_commit_store_1_bits),
		.io_br_res_valid(_alu_io_br_res_valid),
		.io_br_res_bits_mispredicted(_alu_io_br_res_bits_mispredicted),
		.io_br_res_bits_rob_idx(_alu_io_br_res_bits_rob_idx),
		.io_rbk_active(_rob_io_rbk_active),
		.io_rbk_valid(_rob_io_rbk_valid),
		.io_rbk_l_rd(_rob_io_rbk_l_rd),
		.io_rbk_p_rd(_rob_io_rbk_p_rd),
		.io_rbk_stale_p_rd(_rob_io_rbk_stale_p_rd),
		.io_rob_head_idx(_rob_io_rob_head_idx),
		.io_commit_num(io_commit_num),
		.io_bpu_update_valid(io_bpu_update_valid),
		.io_bpu_update_bits_pc(io_bpu_update_bits_pc),
		.io_bpu_update_bits_target(io_bpu_update_bits_target),
		.io_bpu_update_bits_taken(io_bpu_update_bits_taken)
	);
	IssueQueue issue(
		.clock(clock),
		.reset(reset),
		.io_enq_ready(_issue_io_enq_ready),
		.io_enq_valid(dispatch_fire),
		.io_enq_bits_0_valid(_rename_io_deq_bits_0_valid),
		.io_enq_bits_0_pc(_rename_io_deq_bits_0_pc),
		.io_enq_bits_0_inst(_rename_io_deq_bits_0_inst),
		.io_enq_bits_0_fu_code(_rename_io_deq_bits_0_fu_code),
		.io_enq_bits_0_alu_op(_rename_io_deq_bits_0_alu_op),
		.io_enq_bits_0_op1_sel(_rename_io_deq_bits_0_op1_sel),
		.io_enq_bits_0_op2_sel(_rename_io_deq_bits_0_op2_sel),
		.io_enq_bits_0_imm(_rename_io_deq_bits_0_imm),
		.io_enq_bits_0_imm_sel(_rename_io_deq_bits_0_imm_sel),
		.io_enq_bits_0_is_w(_rename_io_deq_bits_0_is_w),
		.io_enq_bits_0_mem_cmd(_rename_io_deq_bits_0_mem_cmd),
		.io_enq_bits_0_mem_size(_rename_io_deq_bits_0_mem_size),
		.io_enq_bits_0_mem_signed(_rename_io_deq_bits_0_mem_signed),
		.io_enq_bits_0_br_type(_rename_io_deq_bits_0_br_type),
		.io_enq_bits_0_l_rd(_rename_io_deq_bits_0_l_rd),
		.io_enq_bits_0_l_rs1(_rename_io_deq_bits_0_l_rs1),
		.io_enq_bits_0_l_rs2(_rename_io_deq_bits_0_l_rs2),
		.io_enq_bits_0_rf_wen(_rename_io_deq_bits_0_rf_wen),
		.io_enq_bits_0_use_rs1(_rename_io_deq_bits_0_use_rs1),
		.io_enq_bits_0_use_rs2(_rename_io_deq_bits_0_use_rs2),
		.io_enq_bits_0_p_rd(_rename_io_deq_bits_0_p_rd),
		.io_enq_bits_0_p_rs1(_rename_io_deq_bits_0_p_rs1),
		.io_enq_bits_0_p_rs2(_rename_io_deq_bits_0_p_rs2),
		.io_enq_bits_0_prs1_ready(_rename_io_deq_bits_0_prs1_ready),
		.io_enq_bits_0_prs2_ready(_rename_io_deq_bits_0_prs2_ready),
		.io_enq_bits_0_stale_p_rd(_rename_io_deq_bits_0_stale_p_rd),
		.io_enq_bits_0_rob_idx(_rob_io_rob_idx_alloc_0),
		.io_enq_bits_0_exception(_rename_io_deq_bits_0_exception),
		.io_enq_bits_0_pred_taken(_rename_io_deq_bits_0_pred_taken),
		.io_enq_bits_0_pred_target(_rename_io_deq_bits_0_pred_target),
		.io_enq_bits_1_valid(_rename_io_deq_bits_1_valid),
		.io_enq_bits_1_pc(_rename_io_deq_bits_1_pc),
		.io_enq_bits_1_inst(_rename_io_deq_bits_1_inst),
		.io_enq_bits_1_fu_code(_rename_io_deq_bits_1_fu_code),
		.io_enq_bits_1_alu_op(_rename_io_deq_bits_1_alu_op),
		.io_enq_bits_1_op1_sel(_rename_io_deq_bits_1_op1_sel),
		.io_enq_bits_1_op2_sel(_rename_io_deq_bits_1_op2_sel),
		.io_enq_bits_1_imm(_rename_io_deq_bits_1_imm),
		.io_enq_bits_1_imm_sel(_rename_io_deq_bits_1_imm_sel),
		.io_enq_bits_1_is_w(_rename_io_deq_bits_1_is_w),
		.io_enq_bits_1_mem_cmd(_rename_io_deq_bits_1_mem_cmd),
		.io_enq_bits_1_mem_size(_rename_io_deq_bits_1_mem_size),
		.io_enq_bits_1_mem_signed(_rename_io_deq_bits_1_mem_signed),
		.io_enq_bits_1_br_type(_rename_io_deq_bits_1_br_type),
		.io_enq_bits_1_l_rd(_rename_io_deq_bits_1_l_rd),
		.io_enq_bits_1_l_rs1(_rename_io_deq_bits_1_l_rs1),
		.io_enq_bits_1_l_rs2(_rename_io_deq_bits_1_l_rs2),
		.io_enq_bits_1_rf_wen(_rename_io_deq_bits_1_rf_wen),
		.io_enq_bits_1_use_rs1(_rename_io_deq_bits_1_use_rs1),
		.io_enq_bits_1_use_rs2(_rename_io_deq_bits_1_use_rs2),
		.io_enq_bits_1_p_rd(_rename_io_deq_bits_1_p_rd),
		.io_enq_bits_1_p_rs1(_rename_io_deq_bits_1_p_rs1),
		.io_enq_bits_1_p_rs2(_rename_io_deq_bits_1_p_rs2),
		.io_enq_bits_1_prs1_ready(_rename_io_deq_bits_1_prs1_ready),
		.io_enq_bits_1_prs2_ready(_rename_io_deq_bits_1_prs2_ready),
		.io_enq_bits_1_stale_p_rd(_rename_io_deq_bits_1_stale_p_rd),
		.io_enq_bits_1_rob_idx(_rob_io_rob_idx_alloc_1),
		.io_enq_bits_1_exception(_rename_io_deq_bits_1_exception),
		.io_enq_bits_1_pred_taken(_rename_io_deq_bits_1_pred_taken),
		.io_enq_bits_1_pred_target(_rename_io_deq_bits_1_pred_target),
		.io_iss_alu_ready(_regread_io_iss_alu_ready),
		.io_iss_alu_valid(_issue_io_iss_alu_valid),
		.io_iss_alu_bits_valid(_issue_io_iss_alu_bits_valid),
		.io_iss_alu_bits_pc(_issue_io_iss_alu_bits_pc),
		.io_iss_alu_bits_inst(_issue_io_iss_alu_bits_inst),
		.io_iss_alu_bits_fu_code(_issue_io_iss_alu_bits_fu_code),
		.io_iss_alu_bits_alu_op(_issue_io_iss_alu_bits_alu_op),
		.io_iss_alu_bits_op1_sel(_issue_io_iss_alu_bits_op1_sel),
		.io_iss_alu_bits_op2_sel(_issue_io_iss_alu_bits_op2_sel),
		.io_iss_alu_bits_imm(_issue_io_iss_alu_bits_imm),
		.io_iss_alu_bits_imm_sel(_issue_io_iss_alu_bits_imm_sel),
		.io_iss_alu_bits_is_w(_issue_io_iss_alu_bits_is_w),
		.io_iss_alu_bits_mem_cmd(_issue_io_iss_alu_bits_mem_cmd),
		.io_iss_alu_bits_mem_size(_issue_io_iss_alu_bits_mem_size),
		.io_iss_alu_bits_mem_signed(_issue_io_iss_alu_bits_mem_signed),
		.io_iss_alu_bits_br_type(_issue_io_iss_alu_bits_br_type),
		.io_iss_alu_bits_l_rd(_issue_io_iss_alu_bits_l_rd),
		.io_iss_alu_bits_l_rs1(_issue_io_iss_alu_bits_l_rs1),
		.io_iss_alu_bits_l_rs2(_issue_io_iss_alu_bits_l_rs2),
		.io_iss_alu_bits_rf_wen(_issue_io_iss_alu_bits_rf_wen),
		.io_iss_alu_bits_use_rs1(_issue_io_iss_alu_bits_use_rs1),
		.io_iss_alu_bits_use_rs2(_issue_io_iss_alu_bits_use_rs2),
		.io_iss_alu_bits_p_rd(_issue_io_iss_alu_bits_p_rd),
		.io_iss_alu_bits_p_rs1(_issue_io_iss_alu_bits_p_rs1),
		.io_iss_alu_bits_p_rs2(_issue_io_iss_alu_bits_p_rs2),
		.io_iss_alu_bits_prs1_ready(_issue_io_iss_alu_bits_prs1_ready),
		.io_iss_alu_bits_prs2_ready(_issue_io_iss_alu_bits_prs2_ready),
		.io_iss_alu_bits_stale_p_rd(_issue_io_iss_alu_bits_stale_p_rd),
		.io_iss_alu_bits_rob_idx(_issue_io_iss_alu_bits_rob_idx),
		.io_iss_alu_bits_exception(_issue_io_iss_alu_bits_exception),
		.io_iss_alu_bits_pred_taken(_issue_io_iss_alu_bits_pred_taken),
		.io_iss_alu_bits_pred_target(_issue_io_iss_alu_bits_pred_target),
		.io_iss_lsu_ready(_regread_io_iss_lsu_ready),
		.io_iss_lsu_valid(_issue_io_iss_lsu_valid),
		.io_iss_lsu_bits_valid(_issue_io_iss_lsu_bits_valid),
		.io_iss_lsu_bits_pc(_issue_io_iss_lsu_bits_pc),
		.io_iss_lsu_bits_inst(_issue_io_iss_lsu_bits_inst),
		.io_iss_lsu_bits_fu_code(_issue_io_iss_lsu_bits_fu_code),
		.io_iss_lsu_bits_alu_op(_issue_io_iss_lsu_bits_alu_op),
		.io_iss_lsu_bits_op1_sel(_issue_io_iss_lsu_bits_op1_sel),
		.io_iss_lsu_bits_op2_sel(_issue_io_iss_lsu_bits_op2_sel),
		.io_iss_lsu_bits_imm(_issue_io_iss_lsu_bits_imm),
		.io_iss_lsu_bits_imm_sel(_issue_io_iss_lsu_bits_imm_sel),
		.io_iss_lsu_bits_is_w(_issue_io_iss_lsu_bits_is_w),
		.io_iss_lsu_bits_mem_cmd(_issue_io_iss_lsu_bits_mem_cmd),
		.io_iss_lsu_bits_mem_size(_issue_io_iss_lsu_bits_mem_size),
		.io_iss_lsu_bits_mem_signed(_issue_io_iss_lsu_bits_mem_signed),
		.io_iss_lsu_bits_br_type(_issue_io_iss_lsu_bits_br_type),
		.io_iss_lsu_bits_l_rd(_issue_io_iss_lsu_bits_l_rd),
		.io_iss_lsu_bits_l_rs1(_issue_io_iss_lsu_bits_l_rs1),
		.io_iss_lsu_bits_l_rs2(_issue_io_iss_lsu_bits_l_rs2),
		.io_iss_lsu_bits_rf_wen(_issue_io_iss_lsu_bits_rf_wen),
		.io_iss_lsu_bits_use_rs1(_issue_io_iss_lsu_bits_use_rs1),
		.io_iss_lsu_bits_use_rs2(_issue_io_iss_lsu_bits_use_rs2),
		.io_iss_lsu_bits_p_rd(_issue_io_iss_lsu_bits_p_rd),
		.io_iss_lsu_bits_p_rs1(_issue_io_iss_lsu_bits_p_rs1),
		.io_iss_lsu_bits_p_rs2(_issue_io_iss_lsu_bits_p_rs2),
		.io_iss_lsu_bits_prs1_ready(_issue_io_iss_lsu_bits_prs1_ready),
		.io_iss_lsu_bits_prs2_ready(_issue_io_iss_lsu_bits_prs2_ready),
		.io_iss_lsu_bits_stale_p_rd(_issue_io_iss_lsu_bits_stale_p_rd),
		.io_iss_lsu_bits_rob_idx(_issue_io_iss_lsu_bits_rob_idx),
		.io_iss_lsu_bits_exception(_issue_io_iss_lsu_bits_exception),
		.io_iss_lsu_bits_pred_taken(_issue_io_iss_lsu_bits_pred_taken),
		.io_iss_lsu_bits_pred_target(_issue_io_iss_lsu_bits_pred_target),
		.io_cdb_0_valid(_alu_io_cdb_valid),
		.io_cdb_0_bits_p_rd(_alu_io_cdb_bits_p_rd),
		.io_cdb_1_valid(_lsu_io_cdb_valid),
		.io_cdb_1_bits_p_rd(_lsu_io_cdb_bits_p_rd),
		.io_flush(_rob_io_flush_pipeline),
		.io_flush_mispredict(_issue_io_flush_mispredict_T),
		.io_mispredict_rob_idx(_alu_io_br_res_bits_rob_idx),
		.io_rob_head_idx(_rob_io_rob_head_idx)
	);
	RegRead regread(
		.clock(clock),
		.reset(reset),
		.io_iss_alu_ready(_regread_io_iss_alu_ready),
		.io_iss_alu_valid(_issue_io_iss_alu_valid),
		.io_iss_alu_bits_valid(_issue_io_iss_alu_bits_valid),
		.io_iss_alu_bits_pc(_issue_io_iss_alu_bits_pc),
		.io_iss_alu_bits_inst(_issue_io_iss_alu_bits_inst),
		.io_iss_alu_bits_fu_code(_issue_io_iss_alu_bits_fu_code),
		.io_iss_alu_bits_alu_op(_issue_io_iss_alu_bits_alu_op),
		.io_iss_alu_bits_op1_sel(_issue_io_iss_alu_bits_op1_sel),
		.io_iss_alu_bits_op2_sel(_issue_io_iss_alu_bits_op2_sel),
		.io_iss_alu_bits_imm(_issue_io_iss_alu_bits_imm),
		.io_iss_alu_bits_imm_sel(_issue_io_iss_alu_bits_imm_sel),
		.io_iss_alu_bits_is_w(_issue_io_iss_alu_bits_is_w),
		.io_iss_alu_bits_mem_cmd(_issue_io_iss_alu_bits_mem_cmd),
		.io_iss_alu_bits_mem_size(_issue_io_iss_alu_bits_mem_size),
		.io_iss_alu_bits_mem_signed(_issue_io_iss_alu_bits_mem_signed),
		.io_iss_alu_bits_br_type(_issue_io_iss_alu_bits_br_type),
		.io_iss_alu_bits_l_rd(_issue_io_iss_alu_bits_l_rd),
		.io_iss_alu_bits_l_rs1(_issue_io_iss_alu_bits_l_rs1),
		.io_iss_alu_bits_l_rs2(_issue_io_iss_alu_bits_l_rs2),
		.io_iss_alu_bits_rf_wen(_issue_io_iss_alu_bits_rf_wen),
		.io_iss_alu_bits_use_rs1(_issue_io_iss_alu_bits_use_rs1),
		.io_iss_alu_bits_use_rs2(_issue_io_iss_alu_bits_use_rs2),
		.io_iss_alu_bits_p_rd(_issue_io_iss_alu_bits_p_rd),
		.io_iss_alu_bits_p_rs1(_issue_io_iss_alu_bits_p_rs1),
		.io_iss_alu_bits_p_rs2(_issue_io_iss_alu_bits_p_rs2),
		.io_iss_alu_bits_prs1_ready(_issue_io_iss_alu_bits_prs1_ready),
		.io_iss_alu_bits_prs2_ready(_issue_io_iss_alu_bits_prs2_ready),
		.io_iss_alu_bits_stale_p_rd(_issue_io_iss_alu_bits_stale_p_rd),
		.io_iss_alu_bits_rob_idx(_issue_io_iss_alu_bits_rob_idx),
		.io_iss_alu_bits_exception(_issue_io_iss_alu_bits_exception),
		.io_iss_alu_bits_pred_taken(_issue_io_iss_alu_bits_pred_taken),
		.io_iss_alu_bits_pred_target(_issue_io_iss_alu_bits_pred_target),
		.io_iss_lsu_ready(_regread_io_iss_lsu_ready),
		.io_iss_lsu_valid(_issue_io_iss_lsu_valid),
		.io_iss_lsu_bits_valid(_issue_io_iss_lsu_bits_valid),
		.io_iss_lsu_bits_pc(_issue_io_iss_lsu_bits_pc),
		.io_iss_lsu_bits_inst(_issue_io_iss_lsu_bits_inst),
		.io_iss_lsu_bits_fu_code(_issue_io_iss_lsu_bits_fu_code),
		.io_iss_lsu_bits_alu_op(_issue_io_iss_lsu_bits_alu_op),
		.io_iss_lsu_bits_op1_sel(_issue_io_iss_lsu_bits_op1_sel),
		.io_iss_lsu_bits_op2_sel(_issue_io_iss_lsu_bits_op2_sel),
		.io_iss_lsu_bits_imm(_issue_io_iss_lsu_bits_imm),
		.io_iss_lsu_bits_imm_sel(_issue_io_iss_lsu_bits_imm_sel),
		.io_iss_lsu_bits_is_w(_issue_io_iss_lsu_bits_is_w),
		.io_iss_lsu_bits_mem_cmd(_issue_io_iss_lsu_bits_mem_cmd),
		.io_iss_lsu_bits_mem_size(_issue_io_iss_lsu_bits_mem_size),
		.io_iss_lsu_bits_mem_signed(_issue_io_iss_lsu_bits_mem_signed),
		.io_iss_lsu_bits_br_type(_issue_io_iss_lsu_bits_br_type),
		.io_iss_lsu_bits_l_rd(_issue_io_iss_lsu_bits_l_rd),
		.io_iss_lsu_bits_l_rs1(_issue_io_iss_lsu_bits_l_rs1),
		.io_iss_lsu_bits_l_rs2(_issue_io_iss_lsu_bits_l_rs2),
		.io_iss_lsu_bits_rf_wen(_issue_io_iss_lsu_bits_rf_wen),
		.io_iss_lsu_bits_use_rs1(_issue_io_iss_lsu_bits_use_rs1),
		.io_iss_lsu_bits_use_rs2(_issue_io_iss_lsu_bits_use_rs2),
		.io_iss_lsu_bits_p_rd(_issue_io_iss_lsu_bits_p_rd),
		.io_iss_lsu_bits_p_rs1(_issue_io_iss_lsu_bits_p_rs1),
		.io_iss_lsu_bits_p_rs2(_issue_io_iss_lsu_bits_p_rs2),
		.io_iss_lsu_bits_prs1_ready(_issue_io_iss_lsu_bits_prs1_ready),
		.io_iss_lsu_bits_prs2_ready(_issue_io_iss_lsu_bits_prs2_ready),
		.io_iss_lsu_bits_stale_p_rd(_issue_io_iss_lsu_bits_stale_p_rd),
		.io_iss_lsu_bits_rob_idx(_issue_io_iss_lsu_bits_rob_idx),
		.io_iss_lsu_bits_exception(_issue_io_iss_lsu_bits_exception),
		.io_iss_lsu_bits_pred_taken(_issue_io_iss_lsu_bits_pred_taken),
		.io_iss_lsu_bits_pred_target(_issue_io_iss_lsu_bits_pred_target),
		.io_exe_alu_valid(_regread_io_exe_alu_valid),
		.io_exe_alu_bits_uop_pc(_regread_io_exe_alu_bits_uop_pc),
		.io_exe_alu_bits_uop_alu_op(_regread_io_exe_alu_bits_uop_alu_op),
		.io_exe_alu_bits_uop_op1_sel(_regread_io_exe_alu_bits_uop_op1_sel),
		.io_exe_alu_bits_uop_op2_sel(_regread_io_exe_alu_bits_uop_op2_sel),
		.io_exe_alu_bits_uop_imm(_regread_io_exe_alu_bits_uop_imm),
		.io_exe_alu_bits_uop_is_w(_regread_io_exe_alu_bits_uop_is_w),
		.io_exe_alu_bits_uop_br_type(_regread_io_exe_alu_bits_uop_br_type),
		.io_exe_alu_bits_uop_p_rd(_regread_io_exe_alu_bits_uop_p_rd),
		.io_exe_alu_bits_uop_rob_idx(_regread_io_exe_alu_bits_uop_rob_idx),
		.io_exe_alu_bits_uop_exception(_regread_io_exe_alu_bits_uop_exception),
		.io_exe_alu_bits_uop_pred_taken(_regread_io_exe_alu_bits_uop_pred_taken),
		.io_exe_alu_bits_uop_pred_target(_regread_io_exe_alu_bits_uop_pred_target),
		.io_exe_alu_bits_rs1_data(_regread_io_exe_alu_bits_rs1_data),
		.io_exe_alu_bits_rs2_data(_regread_io_exe_alu_bits_rs2_data),
		.io_exe_lsu_ready(_lsu_io_req_ready),
		.io_exe_lsu_valid(_regread_io_exe_lsu_valid),
		.io_exe_lsu_bits_uop_imm(_regread_io_exe_lsu_bits_uop_imm),
		.io_exe_lsu_bits_uop_mem_cmd(_regread_io_exe_lsu_bits_uop_mem_cmd),
		.io_exe_lsu_bits_uop_mem_size(_regread_io_exe_lsu_bits_uop_mem_size),
		.io_exe_lsu_bits_uop_mem_signed(_regread_io_exe_lsu_bits_uop_mem_signed),
		.io_exe_lsu_bits_uop_p_rd(_regread_io_exe_lsu_bits_uop_p_rd),
		.io_exe_lsu_bits_uop_rob_idx(_regread_io_exe_lsu_bits_uop_rob_idx),
		.io_exe_lsu_bits_uop_exception(_regread_io_exe_lsu_bits_uop_exception),
		.io_exe_lsu_bits_rs1_data(_regread_io_exe_lsu_bits_rs1_data),
		.io_exe_lsu_bits_rs2_data(_regread_io_exe_lsu_bits_rs2_data),
		.io_prf_alu_req_rs1(_regread_io_prf_alu_req_rs1),
		.io_prf_alu_req_rs2(_regread_io_prf_alu_req_rs2),
		.io_prf_alu_resp_rs1(_prf_io_alu_resp_rs1),
		.io_prf_alu_resp_rs2(_prf_io_alu_resp_rs2),
		.io_prf_lsu_req_rs1(_regread_io_prf_lsu_req_rs1),
		.io_prf_lsu_req_rs2(_regread_io_prf_lsu_req_rs2),
		.io_prf_lsu_resp_rs1(_prf_io_lsu_resp_rs1),
		.io_prf_lsu_resp_rs2(_prf_io_lsu_resp_rs2),
		.io_cdb_0_valid(_alu_io_cdb_valid),
		.io_cdb_0_bits_p_rd(_alu_io_cdb_bits_p_rd),
		.io_cdb_0_bits_data(_alu_io_cdb_bits_data),
		.io_cdb_1_valid(_lsu_io_cdb_valid),
		.io_cdb_1_bits_p_rd(_lsu_io_cdb_bits_p_rd),
		.io_cdb_1_bits_data(_lsu_io_cdb_bits_data)
	);
	PRF prf(
		.clock(clock),
		.reset(reset),
		.io_alu_req_rs1(_regread_io_prf_alu_req_rs1),
		.io_alu_req_rs2(_regread_io_prf_alu_req_rs2),
		.io_alu_resp_rs1(_prf_io_alu_resp_rs1),
		.io_alu_resp_rs2(_prf_io_alu_resp_rs2),
		.io_lsu_req_rs1(_regread_io_prf_lsu_req_rs1),
		.io_lsu_req_rs2(_regread_io_prf_lsu_req_rs2),
		.io_lsu_resp_rs1(_prf_io_lsu_resp_rs1),
		.io_lsu_resp_rs2(_prf_io_lsu_resp_rs2),
		.io_wb_alu_valid(_alu_io_cdb_valid),
		.io_wb_alu_pdst(_alu_io_cdb_bits_p_rd),
		.io_wb_alu_data(_alu_io_cdb_bits_data),
		.io_wb_lsu_valid(_lsu_io_cdb_valid),
		.io_wb_lsu_pdst(_lsu_io_cdb_bits_p_rd),
		.io_wb_lsu_data(_lsu_io_cdb_bits_data)
	);
	ALU_Unit alu(
		.io_req_valid(_regread_io_exe_alu_valid),
		.io_req_bits_uop_pc(_regread_io_exe_alu_bits_uop_pc),
		.io_req_bits_uop_alu_op(_regread_io_exe_alu_bits_uop_alu_op),
		.io_req_bits_uop_op1_sel(_regread_io_exe_alu_bits_uop_op1_sel),
		.io_req_bits_uop_op2_sel(_regread_io_exe_alu_bits_uop_op2_sel),
		.io_req_bits_uop_imm(_regread_io_exe_alu_bits_uop_imm),
		.io_req_bits_uop_is_w(_regread_io_exe_alu_bits_uop_is_w),
		.io_req_bits_uop_br_type(_regread_io_exe_alu_bits_uop_br_type),
		.io_req_bits_uop_p_rd(_regread_io_exe_alu_bits_uop_p_rd),
		.io_req_bits_uop_rob_idx(_regread_io_exe_alu_bits_uop_rob_idx),
		.io_req_bits_uop_exception(_regread_io_exe_alu_bits_uop_exception),
		.io_req_bits_uop_pred_taken(_regread_io_exe_alu_bits_uop_pred_taken),
		.io_req_bits_uop_pred_target(_regread_io_exe_alu_bits_uop_pred_target),
		.io_req_bits_rs1_data(_regread_io_exe_alu_bits_rs1_data),
		.io_req_bits_rs2_data(_regread_io_exe_alu_bits_rs2_data),
		.io_cdb_valid(_alu_io_cdb_valid),
		.io_cdb_bits_rob_idx(_alu_io_cdb_bits_rob_idx),
		.io_cdb_bits_p_rd(_alu_io_cdb_bits_p_rd),
		.io_cdb_bits_data(_alu_io_cdb_bits_data),
		.io_cdb_bits_exc(_alu_io_cdb_bits_exc),
		.io_cdb_bits_is_branch(_alu_io_cdb_bits_is_branch),
		.io_cdb_bits_br_taken(_alu_io_cdb_bits_br_taken),
		.io_cdb_bits_br_target(_alu_io_cdb_bits_br_target),
		.io_cdb_bits_br_pc(_alu_io_cdb_bits_br_pc),
		.io_br_redirect(_alu_io_br_redirect),
		.io_br_redirect_pc(_alu_io_br_redirect_pc),
		.io_br_res_valid(_alu_io_br_res_valid),
		.io_br_res_bits_mispredicted(_alu_io_br_res_bits_mispredicted),
		.io_br_res_bits_rob_idx(_alu_io_br_res_bits_rob_idx)
	);
	LSU_Unit lsu(
		.clock(clock),
		.reset(reset),
		.io_req_ready(_lsu_io_req_ready),
		.io_req_valid(_regread_io_exe_lsu_valid),
		.io_req_bits_uop_imm(_regread_io_exe_lsu_bits_uop_imm),
		.io_req_bits_uop_mem_cmd(_regread_io_exe_lsu_bits_uop_mem_cmd),
		.io_req_bits_uop_mem_size(_regread_io_exe_lsu_bits_uop_mem_size),
		.io_req_bits_uop_mem_signed(_regread_io_exe_lsu_bits_uop_mem_signed),
		.io_req_bits_uop_p_rd(_regread_io_exe_lsu_bits_uop_p_rd),
		.io_req_bits_uop_rob_idx(_regread_io_exe_lsu_bits_uop_rob_idx),
		.io_req_bits_uop_exception(_regread_io_exe_lsu_bits_uop_exception),
		.io_req_bits_rs1_data(_regread_io_exe_lsu_bits_rs1_data),
		.io_req_bits_rs2_data(_regread_io_exe_lsu_bits_rs2_data),
		.io_cdb_valid(_lsu_io_cdb_valid),
		.io_cdb_bits_rob_idx(_lsu_io_cdb_bits_rob_idx),
		.io_cdb_bits_p_rd(_lsu_io_cdb_bits_p_rd),
		.io_cdb_bits_data(_lsu_io_cdb_bits_data),
		.io_cdb_bits_exc(_lsu_io_cdb_bits_exc),
		.io_dmem_req_ready(io_dmem_req_ready),
		.io_dmem_req_valid(io_dmem_req_valid),
		.io_dmem_req_bits_addr(io_dmem_req_bits_addr),
		.io_dmem_req_bits_data(io_dmem_req_bits_data),
		.io_dmem_req_bits_cmd(io_dmem_req_bits_cmd),
		.io_dmem_req_bits_size(io_dmem_req_bits_size),
		.io_dmem_resp_valid(io_dmem_resp_valid),
		.io_dmem_resp_bits_data(io_dmem_resp_bits_data),
		.io_commit_store_0_valid(_rob_io_commit_store_0_valid),
		.io_commit_store_0_bits(_rob_io_commit_store_0_bits),
		.io_commit_store_1_valid(_rob_io_commit_store_1_valid),
		.io_commit_store_1_bits(_rob_io_commit_store_1_bits),
		.io_flush_mispredict(_issue_io_flush_mispredict_T),
		.io_mispredict_rob_idx(_alu_io_br_res_bits_rob_idx),
		.io_rob_head_idx(_rob_io_rob_head_idx),
		.io_flush(_rob_io_flush_pipeline)
	);
	assign io_redirect_valid = _alu_io_br_redirect | _rob_io_flush_pipeline;
	assign io_redirect_pc = (_alu_io_br_redirect ? _alu_io_br_redirect_pc : 64'h0000000000000000);
endmodule
module MyCoreTop (
	clock,
	reset,
	io_imem_req_ready,
	io_imem_req_valid,
	io_imem_req_bits_addr,
	io_imem_req_bits_data,
	io_imem_req_bits_cmd,
	io_imem_req_bits_size,
	io_imem_resp_valid,
	io_imem_resp_bits_data,
	io_dmem_req_ready,
	io_dmem_req_valid,
	io_dmem_req_bits_addr,
	io_dmem_req_bits_data,
	io_dmem_req_bits_cmd,
	io_dmem_req_bits_size,
	io_dmem_resp_valid,
	io_dmem_resp_bits_data,
	io_commit_count
);
	input clock;
	input reset;
	input io_imem_req_ready;
	output wire io_imem_req_valid;
	output wire [63:0] io_imem_req_bits_addr;
	output wire [63:0] io_imem_req_bits_data;
	output wire [2:0] io_imem_req_bits_cmd;
	output wire [1:0] io_imem_req_bits_size;
	input io_imem_resp_valid;
	input [63:0] io_imem_resp_bits_data;
	input io_dmem_req_ready;
	output wire io_dmem_req_valid;
	output wire [63:0] io_dmem_req_bits_addr;
	output wire [63:0] io_dmem_req_bits_data;
	output wire [2:0] io_dmem_req_bits_cmd;
	output wire [1:0] io_dmem_req_bits_size;
	input io_dmem_resp_valid;
	input [63:0] io_dmem_resp_bits_data;
	output wire [3:0] io_commit_count;
	wire _backend_io_from_frontend_ready;
	wire _backend_io_redirect_valid;
	wire [63:0] _backend_io_redirect_pc;
	wire [1:0] _backend_io_commit_num;
	wire _backend_io_bpu_update_valid;
	wire [63:0] _backend_io_bpu_update_bits_pc;
	wire [63:0] _backend_io_bpu_update_bits_target;
	wire _backend_io_bpu_update_bits_taken;
	wire _frontend_io_fetch_packet_valid;
	wire [31:0] _frontend_io_fetch_packet_bits_0_inst;
	wire [63:0] _frontend_io_fetch_packet_bits_0_pc;
	wire _frontend_io_fetch_packet_bits_0_valid;
	wire _frontend_io_fetch_packet_bits_0_pred_taken;
	wire [63:0] _frontend_io_fetch_packet_bits_0_pred_target;
	wire [31:0] _frontend_io_fetch_packet_bits_1_inst;
	wire [63:0] _frontend_io_fetch_packet_bits_1_pc;
	wire _frontend_io_fetch_packet_bits_1_valid;
	wire _frontend_io_fetch_packet_bits_1_pred_taken;
	wire [63:0] _frontend_io_fetch_packet_bits_1_pred_target;
	FrontEnd frontend(
		.clock(clock),
		.reset(reset),
		.io_imem_req_ready(io_imem_req_ready),
		.io_imem_req_valid(io_imem_req_valid),
		.io_imem_req_bits_addr(io_imem_req_bits_addr),
		.io_imem_resp_valid(io_imem_resp_valid),
		.io_imem_resp_bits_data(io_imem_resp_bits_data),
		.io_fetch_packet_ready(_backend_io_from_frontend_ready),
		.io_fetch_packet_valid(_frontend_io_fetch_packet_valid),
		.io_fetch_packet_bits_0_inst(_frontend_io_fetch_packet_bits_0_inst),
		.io_fetch_packet_bits_0_pc(_frontend_io_fetch_packet_bits_0_pc),
		.io_fetch_packet_bits_0_valid(_frontend_io_fetch_packet_bits_0_valid),
		.io_fetch_packet_bits_0_pred_taken(_frontend_io_fetch_packet_bits_0_pred_taken),
		.io_fetch_packet_bits_0_pred_target(_frontend_io_fetch_packet_bits_0_pred_target),
		.io_fetch_packet_bits_1_inst(_frontend_io_fetch_packet_bits_1_inst),
		.io_fetch_packet_bits_1_pc(_frontend_io_fetch_packet_bits_1_pc),
		.io_fetch_packet_bits_1_valid(_frontend_io_fetch_packet_bits_1_valid),
		.io_fetch_packet_bits_1_pred_taken(_frontend_io_fetch_packet_bits_1_pred_taken),
		.io_fetch_packet_bits_1_pred_target(_frontend_io_fetch_packet_bits_1_pred_target),
		.io_redirect_valid(_backend_io_redirect_valid),
		.io_redirect_pc(_backend_io_redirect_pc),
		.io_bpu_update_valid(_backend_io_bpu_update_valid),
		.io_bpu_update_bits_pc(_backend_io_bpu_update_bits_pc),
		.io_bpu_update_bits_target(_backend_io_bpu_update_bits_target),
		.io_bpu_update_bits_taken(_backend_io_bpu_update_bits_taken)
	);
	BackEndTOP backend(
		.clock(clock),
		.reset(reset),
		.io_from_frontend_ready(_backend_io_from_frontend_ready),
		.io_from_frontend_valid(_frontend_io_fetch_packet_valid),
		.io_from_frontend_bits_0_inst(_frontend_io_fetch_packet_bits_0_inst),
		.io_from_frontend_bits_0_pc(_frontend_io_fetch_packet_bits_0_pc),
		.io_from_frontend_bits_0_valid(_frontend_io_fetch_packet_bits_0_valid),
		.io_from_frontend_bits_0_pred_taken(_frontend_io_fetch_packet_bits_0_pred_taken),
		.io_from_frontend_bits_0_pred_target(_frontend_io_fetch_packet_bits_0_pred_target),
		.io_from_frontend_bits_1_inst(_frontend_io_fetch_packet_bits_1_inst),
		.io_from_frontend_bits_1_pc(_frontend_io_fetch_packet_bits_1_pc),
		.io_from_frontend_bits_1_valid(_frontend_io_fetch_packet_bits_1_valid),
		.io_from_frontend_bits_1_pred_taken(_frontend_io_fetch_packet_bits_1_pred_taken),
		.io_from_frontend_bits_1_pred_target(_frontend_io_fetch_packet_bits_1_pred_target),
		.io_redirect_valid(_backend_io_redirect_valid),
		.io_redirect_pc(_backend_io_redirect_pc),
		.io_commit_num(_backend_io_commit_num),
		.io_dmem_req_ready(io_dmem_req_ready),
		.io_dmem_req_valid(io_dmem_req_valid),
		.io_dmem_req_bits_addr(io_dmem_req_bits_addr),
		.io_dmem_req_bits_data(io_dmem_req_bits_data),
		.io_dmem_req_bits_cmd(io_dmem_req_bits_cmd),
		.io_dmem_req_bits_size(io_dmem_req_bits_size),
		.io_dmem_resp_valid(io_dmem_resp_valid),
		.io_dmem_resp_bits_data(io_dmem_resp_bits_data),
		.io_bpu_update_valid(_backend_io_bpu_update_valid),
		.io_bpu_update_bits_pc(_backend_io_bpu_update_bits_pc),
		.io_bpu_update_bits_target(_backend_io_bpu_update_bits_target),
		.io_bpu_update_bits_taken(_backend_io_bpu_update_bits_taken)
	);
	assign io_imem_req_bits_data = 64'h0000000000000000;
	assign io_imem_req_bits_cmd = 3'h1;
	assign io_imem_req_bits_size = 2'h0;
	assign io_commit_count = {2'h0, _backend_io_commit_num};
endmodule