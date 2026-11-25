// Antirrebote para un botón activo en bajo.
// Sincroniza la entrada, espera a que se estabilice ESTABLE ciclos
// y entrega un pulso de un ciclo en cada pulsación.
module debounce #(
    parameter ESTABLE = 270_000         // 10 ms a 27 MHz
) (
    input  clk,
    input  rst_n,
    input  btn_n,                       // botón crudo, 0 = presionado
    output reg pulso
);

localparam W = $clog2(ESTABLE);

// Sincronizador de dos flip-flops, evita metaestabilidad
reg [1:0] sync;
always @(posedge clk or negedge rst_n)
    if (!rst_n) sync <= 2'b11;
    else        sync <= {sync[0], btn_n};

reg [W-1:0] cuenta;
reg         estado;                     // 1 = suelto, 0 = presionado

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cuenta <= 0;
        estado <= 1'b1;
        pulso  <= 1'b0;
    end else begin
        pulso <= 1'b0;
        if (sync[1] == estado) begin
            cuenta <= 0;                // sin cambio, reinicia la espera
        end else if (cuenta == ESTABLE - 1) begin
            cuenta <= 0;
            estado <= sync[1];          // cambio confirmado
            if (sync[1] == 1'b0)
                pulso <= 1'b1;          // flanco de presión
        end else begin
            cuenta <= cuenta + 1'b1;
        end
    end
end

endmodule
