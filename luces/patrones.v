// Calcula el patrón de 6 LEDs. Avanza un paso en cada tick.
// modo 0: corrimiento circular
// modo 1: ida y vuelta (un LED rebota de un extremo al otro)
// modo 2: contador binario
// modo 3: parpadeo de todos
module patrones (
    input            clk,
    input            rst_n,
    input            tick,
    input      [1:0] modo,
    output reg [5:0] leds              // 1 = encendido
);

reg       dir;                          // 0 = hacia arriba, 1 = hacia abajo
reg [5:0] cuenta;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        leds   <= 6'b000001;
        dir    <= 1'b0;
        cuenta <= 6'd0;
    end else if (tick) begin
        case (modo)
            2'd0: leds <= (leds == 6'b0 || leds[5]) ? 6'b000001 : {leds[4:0], 1'b0};
            2'd1: begin
                if (leds == 6'b0) begin
                    leds <= 6'b000001;
                    dir  <= 1'b0;
                end else if (!dir) begin
                    leds <= {leds[4:0], 1'b0};
                    if (leds[4]) dir <= 1'b1;
                end else begin
                    leds <= {1'b0, leds[5:1]};
                    if (leds[1]) dir <= 1'b0;
                end
            end
            2'd2: begin
                cuenta <= cuenta + 1'b1;
                leds   <= cuenta + 1'b1;
            end
            2'd3: leds <= (leds == 6'b111111) ? 6'b000000 : 6'b111111;
        endcase
    end
end

endmodule
