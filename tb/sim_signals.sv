module sim_signals #(
    parameter ADC_W,
    parameter SYSRG_W
)(
    output logic [2:0]  hall_sensor,    
    output logic [1:0]  encoder,    
    output logic [15:0] pwm_cmp[2:0],  
    output logic [15:0] abc_voltage[2:0],
    
    output logic signed[SYSRG_W-1:0]velocity_command,
    output logic signed[SYSRG_W-1:0]velocity_measured,
    output logic [ADC_W-1:0]phase_current[1:0],
    output logic signed[SYSRG_W-1:0]electrical_position
);

localparam VOLTAGE              = 24;
localparam MAX_SPEED            = 300; // +-300rad/sec -> 18000rpm
localparam MAX_PHASE_CURRENT    = 10;

sim_ssignal#(
    .FNAME("./msim_data/electrical_position.msim"),
    .WIDTH      ( SYSRG_W        ),
    //.MIN        ( -6.283185307179586476925286766559  ),
    //.MAX        ( 6.283185307179586476925286766559   )
    .MIN        ( -6.283185482025146484375  ),
    .MAX        ( 6.283185482025146484375   )
)
e_posiiton  (
    .out     ( electrical_position     )
);

//-----------------------------------------------------------
// Phase current
//-----------------------------------------------------------
sim_adcsignal#( 
    .FNAME("./msim_data/phase_current_0.msim"),
    .WIDTH      ( ADC_W                 ),
    .MIN        ( -MAX_PHASE_CURRENT    ),
    .MAX        ( MAX_PHASE_CURRENT     )
)
phase_curr_0  (
    .out     ( phase_current[0]     )
);

sim_adcsignal#( 
    .FNAME("./msim_data/phase_current_1.msim"),
    .WIDTH      ( ADC_W                 ),
    .MIN        ( -MAX_PHASE_CURRENT    ),
    .MAX        ( MAX_PHASE_CURRENT     )
)
phase_curr_1  (
    .out     ( phase_current[1]     )
);

//-----------------------------------------------------------
// Velocity
//-----------------------------------------------------------
sim_ssignal#(
    .FNAME("./msim_data/velocitycommand.msim"),
    .WIDTH      ( 18        ),
    .MIN        ( -MAX_SPEED   ),
    .MAX        ( MAX_SPEED   )
)
velocity_cmd  (
    .out     ( velocity_command     )
);

sim_ssignal#( 
    .FNAME("./msim_data/velocity_measured.msim"),
    .WIDTH      ( 18        ),
    .MIN        ( -MAX_SPEED   ),
    .MAX        ( MAX_SPEED   )
)
velocity_sns  (
    .out     ( velocity_measured     )
);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
sim_bsignal#( .FNAME("./msim_data/hall_sensor_0.msim")  )
hall_0  (
    .out     ( hall_sensor[0]     )
);

sim_bsignal#( .FNAME("./msim_data/hall_sensor_1.msim")  )
hall_1  (
    .out     ( hall_sensor[1]     )
);

sim_bsignal#( .FNAME("./msim_data/hall_sensor_2.msim")  )
hall_2  (
    .out     ( hall_sensor[2]     )
);

//-----------------------------------------------------------
sim_bsignal#( .FNAME("./msim_data/encoder_sensor_0.msim")  )
enc_0  (
    .out     ( encoder[0]     )
);

sim_bsignal#( .FNAME("./msim_data/encoder_sensor_1.msim")  )
enc_1  (
    .out     ( encoder[1]     )
);

//-----------------------------------------------------------
sim_usignal#( .FNAME("./msim_data/pwmcompare_0.msim")  )
pwmcompare_0  (
    .out     ( pwm_cmp[0]     )
);

sim_usignal#( .FNAME("./msim_data/pwmcompare_1.msim")  )
pwmcompare_1  (
    .out     ( pwm_cmp[1]     )
);

sim_usignal#( .FNAME("./msim_data/pwmcompare_2.msim")  )
pwmcompare_2  (
    .out     ( pwm_cmp[2]     )
);

//-----------------------------------------------------------
sim_adcsignal#( 
    .FNAME("./msim_data/abcvoltage_0.msim"),
    .WIDTH      ( 16        ),
    .MIN        ( -VOLTAGE   ),
    .MAX        ( VOLTAGE   )
)
abc_voltage_0  (
    .out     ( abc_voltage[0]     )
);

sim_adcsignal#( 
    .FNAME("./msim_data/abcvoltage_1.msim"),
    .WIDTH      ( 16        ),
    .MIN        ( -VOLTAGE   ),
    .MAX        ( VOLTAGE   )
)
abc_voltage_1  (
    .out     ( abc_voltage[1]     )
);

sim_adcsignal#( 
    .FNAME("./msim_data/abcvoltage_2.msim"),
    .WIDTH      ( 16        ),
    .MIN        ( -VOLTAGE   ),
    .MAX        ( VOLTAGE   )
)
abc_voltage_2  (
    .out     ( abc_voltage[2]     )
);
//-----------------------------------------------------------


endmodule

