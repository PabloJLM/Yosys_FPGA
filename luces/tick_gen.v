// Genera un pulso de un ciclo cada PERIODO ciclos de reloj.
module tick_gen #(
    parameter PERIODO = 27_000_000      // 1 s a 27 MHz
) (
    input  clk,
    input  rst_n,
    output reg tick
);

localparam W = $clog2(PERIODO);
reg [W-1:0] cuenta;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cuenta <= 0;
        tick   <= 1'b0;
    end else if (cuenta == PERIODO - 1) begin
        cuenta <= 0;
        tick   <= 1'b1;
    end else begin
        cuenta <= cuenta + 1'b1;
        tick   <= 1'b0;
    end
end

endmodule
