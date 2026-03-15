/***********************************************************************************************/
/*********************************  MIPS 5-stage pipeline implementation ***********************/
/***********************************************************************************************/

module cpu(input clock, input reset);
 reg [31:0] PC; 
 reg [31:0] IFID_PCplus4;
 reg [31:0] IFID_instr;
 reg [31:0] IDEX_rdA, IDEX_rdB, IDEX_signExtend, IDEX_PCplus4;
 reg [4:0]  IDEX_instr_rt, IDEX_instr_rs, IDEX_instr_rd, IDEX_Shamt;                            
 reg        IDEX_RegDst, IDEX_ALUSrc;
 reg [1:0]  IDEX_ALUcntrl;
 reg        IDEX_Branch, IDEX_MemRead, IDEX_MemWrite, IDEX_BranchDecision; 
 reg        IDEX_MemToReg, IDEX_RegWrite;                
 reg [4:0]  EXMEM_RegWriteAddr, EXMEM_instr_rd; 
 reg [31:0] EXMEM_ALUOut, EXMEM_PCBranch;
 reg        EXMEM_Zero;
 reg [31:0] EXMEM_MemWriteData;
 reg        EXMEM_Branch, EXMEM_MemRead, EXMEM_MemWrite, EXMEM_RegWrite, EXMEM_MemToReg, EXMEM_BranchDecision;
 reg [31:0] MEMWB_DMemOut;
 reg [4:0]  MEMWB_RegWriteAddr, MEMWB_instr_rd; 
 reg [31:0] MEMWB_ALUOut;
 reg        MEMWB_MemToReg, MEMWB_RegWrite;               
 wire [31:0] instr, ALUInA, ALUInB, ALUOut, rdA, rdB, signExtend, DMemOut, wRegData, PCIncr, ALUshamt;
 wire Zero, RegDst, MemRead, MemWrite, MemToReg, ALUSrc, RegWrite, Branch;
 wire [5:0] opcode, func;
 wire [4:0] instr_rs, instr_rt, instr_rd, RegWriteAddr;
 wire [3:0] ALUOp;
 wire [1:0] ALUcntrl;
 wire [15:0] imm;
 wire [1:0] ForwardA, ForwardB;
 wire bubble_idex, IFID_Write, PC_write, BranchDecision, PCSrc, Jump;           
 wire [31:0] EX_RegB;
 wire [25:0] jumpLocation;

/***************** Instruction Fetch Unit (IF)  ****************/
 always @(posedge clock or negedge reset)
  begin 
    if (reset == 1'b0)     
       PC <= -1;     
    else if (PC == -1)
       PC <= 0;
    else if (PC_write) //if not stall
      if((Jump) && (IDEX_Branch)) //if branch and then jump, stall the jump in order to check the branch first
        PC <= PC;
      else if(PCSrc)
        PC <= EXMEM_PCBranch;
      else if(Jump)
        PC <= IFID_instr[25:0] << 2;  //I put exactly the IFID_instr[25:0] here and not the jumpLocation in order not to loose a cycle
      else
       PC <= PC + 4;
  end
  
  // IFID pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if (reset == 1'b0)     
       IFID_instr <= 32'b0;
    else if ((Jump) && (IDEX_Branch == 1'b0)) //if jump and then not branch, one stall
      begin
        IFID_instr <= 32'b0;
        IFID_PCplus4 <= 32'b0;
      end
    else if (IFID_Write) //if not stall
      begin
       IFID_instr <= instr;
       IFID_PCplus4 <= PC + 32'd4;
      end
  end
  
// TO FILL IN: Instantiate the Instruction Memory here 
Memory cpu_IMem (
    .clock(clock),
    .reset(reset),
    .ren(1'b1),  // Always enable reading
    .wen(1'b0),   // Never enable writing
    .addr(PC/4),   // We want the instructions to increment by 1 each time, not by 4
    .din(32'b0),   // Data input not used
    .dout(instr)  // Output instruction
  );  
  
  

/***************** Instruction Decode Unit (ID)  ****************/
assign opcode = IFID_instr[31:26];
assign func = IFID_instr[5:0];
assign instr_rs = IFID_instr[25:21];
assign instr_rt = IFID_instr[20:16];
assign instr_rd = IFID_instr[15:11];
assign imm = IFID_instr[15:0];
assign signExtend = {{16{imm[15]}}, imm};
assign ALUshamt = IFID_instr[10:6];
assign jumpLocation = IFID_instr[25:0];

// Register file
RegFile cpu_regs(clock, reset, instr_rs, instr_rt, MEMWB_RegWriteAddr, MEMWB_RegWrite, wRegData, rdA, rdB); //with RegWrite is meant wen for regfile

  // IDEX pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if ((reset == 1'b0) || (bubble_idex)) //if reset or stall (either from branch or from jump, nothing changes here)
      begin
       IDEX_rdA <= 32'b0;    
       IDEX_rdB <= 32'b0;
       IDEX_signExtend <= 32'b0;
       IDEX_instr_rd <= 5'b0;
       IDEX_instr_rs <= 5'b0;
       IDEX_instr_rt <= 5'b0;
       IDEX_RegDst <= 1'b0;
       IDEX_ALUcntrl <= 2'b0;
       IDEX_ALUSrc <= 1'b0;
       IDEX_Branch <= 1'b0;
       IDEX_MemRead <= 1'b0;
       IDEX_MemWrite <= 1'b0;
       IDEX_MemToReg <= 1'b0;                  
       IDEX_RegWrite <= 1'b0;
       IDEX_Shamt <= 1'b0;
       IDEX_BranchDecision <= 1'b0;
       IDEX_PCplus4 <= 1'b0;
    end 
    else 
      begin
       IDEX_rdA <= rdA;
       IDEX_rdB <= rdB;
       IDEX_signExtend <= signExtend;
       IDEX_instr_rd <= instr_rd;
       IDEX_instr_rs <= instr_rs;
       IDEX_instr_rt <= instr_rt;
       IDEX_RegDst <= RegDst;
       IDEX_ALUcntrl <= ALUcntrl;
       IDEX_ALUSrc <= ALUSrc;
       IDEX_Branch <= Branch;
       IDEX_MemRead <= MemRead;
       IDEX_MemWrite <= MemWrite;
       IDEX_MemToReg <= MemToReg;                  
       IDEX_RegWrite <= RegWrite;
       IDEX_Shamt <= ALUshamt;
       IDEX_BranchDecision <= BranchDecision;
       IDEX_PCplus4 <= IFID_PCplus4;
    end
  end

// Main Control Unit 
control_main control_main (RegDst,
                  Branch,
                  MemRead,
                  MemWrite,
                  MemToReg,                                                  
                  ALUSrc,                  
                  RegWrite,                
                  ALUcntrl,               
                  BranchDecision,
                  Jump,
                  opcode);
                  
// TO FILL IN: Instantiation of Control Unit that generates stalls
Hazard_Unit hazard_unit(IDEX_instr_rt,                              
                   IDEX_MemRead,
                   instr_rs,
                   instr_rt,
                   PCSrc,
                   PC_write,
                   bubble_idex,
                   IFID_Write);


                           
/***************** Execution Unit (EX)  ****************/
assign PCSrc = ((EXMEM_Branch && EXMEM_Zero) || (EXMEM_BranchDecision && (!EXMEM_Zero))) ? 1 : 0;  //basically an inverter in order to know if we have Beq or Bne
assign PCIncr = (IDEX_PCplus4 + (IDEX_signExtend << 2));

assign ALUInA =   (ForwardA == 0) ? IDEX_rdA :
                  (ForwardA == 1) ? wRegData : EXMEM_ALUOut;

assign EX_RegB =  (ForwardB == 0) ? IDEX_rdB :
                  (ForwardB == 1) ? wRegData : EXMEM_ALUOut;

assign ALUInB = (IDEX_ALUSrc == 1'b0) ? ((ForwardB == 0) ? IDEX_rdB : ((ForwardB == 1) ? wRegData : EXMEM_ALUOut)) : IDEX_signExtend; // The EX_RegB is not put here because if this is done the result is
                                                                                                                                      // a cycle late and we want the result immediately

//  ALU
ALU  #(32) cpu_alu(ALUOut, Zero, ALUInA, ALUInB, ALUOp, IDEX_Shamt); //IDEX_Shhamt is needed here because the ALUshamt changes 

assign RegWriteAddr = (IDEX_RegDst==1'b0) ? IDEX_instr_rt : IDEX_instr_rd;

 // EXMEM pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if ((reset == 1'b0) || (bubble_idex && PCSrc)) //if stall because of branch (because the branch executes in the EX/MEM and then I have to 
      begin                                        //initialize this register and the jump executes earlier so initialization is not needed in that case)
       EXMEM_ALUOut <= 32'b0;    
       EXMEM_RegWriteAddr <= 5'b0;
       EXMEM_MemWriteData <= 32'b0;
       EXMEM_Zero <= 1'b0;
       EXMEM_Branch <= 1'b0;
       EXMEM_MemRead <= 1'b0;
       EXMEM_MemWrite <= 1'b0;
       EXMEM_MemToReg <= 1'b0;                  
       EXMEM_RegWrite <= 1'b0;
       EXMEM_BranchDecision <= 1'b0;
       EXMEM_PCBranch <= 1'b0;
      end 
    else 
      begin
       EXMEM_ALUOut <= ALUOut;    
       EXMEM_RegWriteAddr <= RegWriteAddr;
       EXMEM_MemWriteData <= ((ForwardB == 0) ? IDEX_rdB : ((ForwardB == 1) ? wRegData : EXMEM_ALUOut));           //We put the EX_RegB (not exactly that because it's one cyrcle late, so I did what 
       EXMEM_Zero <= Zero;                                                                                         //I did above in the ALUInB) instead of IDEX_rdB because we may have bypass and then sw for example
       EXMEM_Branch <= IDEX_Branch;
       EXMEM_MemRead <= IDEX_MemRead;
       EXMEM_MemWrite <= IDEX_MemWrite;
       EXMEM_MemToReg <= IDEX_MemToReg;                  
       EXMEM_RegWrite <= IDEX_RegWrite;
       EXMEM_BranchDecision <= IDEX_BranchDecision;
       EXMEM_PCBranch <= PCIncr;
      end
  end
  
  // ALU control
  control_alu control_alu(ALUOp, IDEX_ALUcntrl, IDEX_signExtend[5:0]);
  
   // TO FILL IN: Instantiation of control logic for Forwarding goes here
  Forward_Unit forward_unit(EXMEM_RegWriteAddr,
                            EXMEM_RegWrite,
                            MEMWB_RegWriteAddr,
                            MEMWB_RegWrite,
                            IDEX_instr_rt,
                            IDEX_instr_rs,
                            ForwardA,
                            ForwardB);

  
  
  
/***************** Memory Unit (MEM)  ****************/  

// Data memory 1KB
// Instantiate the Data Memory here 
Memory cpu_DMem (
    .clock(clock),
    .reset(reset),
    .ren(EXMEM_MemRead),  // Read Enable controlled by control unit (for lw)
    .wen(EXMEM_MemWrite),  // Write Enable controlled by control unit (for sw)
    .addr(EXMEM_ALUOut),  // Address calculated by ALU
    .din(EXMEM_MemWriteData), // Data to be written (for sw)                     
    .dout(DMemOut)   // Data read (for lw)
  );


// MEMWB pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if (reset == 1'b0)     
      begin
       MEMWB_DMemOut <= 32'b0;    
       MEMWB_ALUOut <= 32'b0;
       MEMWB_RegWriteAddr <= 5'b0;
       MEMWB_MemToReg <= 1'b0;                  
       MEMWB_RegWrite <= 1'b0;
      end 
    else 
      begin
       MEMWB_DMemOut <= DMemOut;
       MEMWB_ALUOut <= EXMEM_ALUOut;
       MEMWB_RegWriteAddr <= EXMEM_RegWriteAddr;
       MEMWB_MemToReg <= EXMEM_MemToReg;                  
       MEMWB_RegWrite <= EXMEM_RegWrite;
      end
  end

  
  
  

/***************** WriteBack Unit (WB)  ****************/  
// TO FILL IN: Write Back logic 
assign wRegData = (MEMWB_MemToReg) ? MEMWB_DMemOut : MEMWB_ALUOut;

endmodule
