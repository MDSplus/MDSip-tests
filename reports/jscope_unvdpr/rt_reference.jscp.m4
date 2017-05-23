Scope.geometry: 1270x988+48+0
Scope.update.disable: false
Scope.update.disable_when_icon: true
Scope.font: java.awt.Font[[family=Dialog,name=Dialog,style=plain,size=14]]


Scope.color_0: Black,java.awt.Color[[r=0,g=0,b=0]]
Scope.color_1: Blue,java.awt.Color[[r=0,g=0,b=255]]
Scope.color_2: Cyan,java.awt.Color[[r=0,g=255,b=255]]
Scope.color_3: DarkGray,java.awt.Color[[r=64,g=64,b=64]]
Scope.color_4: Gray,java.awt.Color[[r=128,g=128,b=128]]
Scope.color_5: Green,java.awt.Color[[r=0,g=255,b=0]]
Scope.color_6: LightGray,java.awt.Color[[r=192,g=192,b=192]]
Scope.color_7: Magenta,java.awt.Color[[r=255,g=0,b=255]]
Scope.color_8: Orange,java.awt.Color[[r=255,g=200,b=0]]
Scope.color_9: Pink,java.awt.Color[[r=255,g=175,b=175]]
Scope.color_10: Red,java.awt.Color[[r=255,g=0,b=0]]
Scope.color_11: Yellow,java.awt.Color[[r=255,g=255,b=0]]

Scope.title: $shotname
Scope.data_server_name: _TARGET_HOST___TARGET_PORT_
Scope.data_server_class: MdsDataProvider
Scope.data_server_argument: _TARGET_HOST_:_TARGET_PORT_
Scope.fast_network_access: false
Scope.reversed: false

Scope.global_1_1.experiment: rfx
Scope.global_1_1.shot: 39391
Scope.global_1_1.xmax: .140
Scope.global_1_1.xmin: -.010
Scope.global_1_1.horizontal_offset: 0
Scope.global_1_1.vertical_offset: 0

Scope.columns: 3
Scope.rows_in_column_1: 4


Scope.plot_1_1.height: 218
Scope.plot_1_1.grid_mode: 0
Scope.plot_1_1.x_log: false
Scope.plot_1_1.y_log: false
Scope.plot_1_1.update_limits: true
Scope.plot_1_1.palette: Green scale
Scope.plot_1_1.bitShift: 0
Scope.plot_1_1.bitClip: false
Scope.plot_1_1.num_expr: 4
Scope.plot_1_1.num_shot: 1
Scope.plot_1_1.shot: 0
Scope.plot_1_1.xmin: \RFX::T_INSRT_PTCB_1-0.01
Scope.plot_1_1.xmax: \RFX::T_STOP_PC+0.1
Scope.plot_1_1.title: "Ip Corrente di camera e di plasma  "//$shotname
Scope.plot_1_1.global_defaults: 187777
Scope.plot_1_1.x_expr_1: dim_of(\dequ::vmvt003_vd2va)
Scope.plot_1_1.y_expr_1: \dequ::vmrg120_vi2va-\dequ::vmvt003_vd2va/1.23e-3
Scope.plot_1_1.mode_1D_1_1: Line
Scope.plot_1_1.mode_2D_1_1: xz(y)
Scope.plot_1_1.color_1_1: 10
Scope.plot_1_1.marker_1_1: 0
Scope.plot_1_1.step_marker_1_1: 1
Scope.plot_1_1.x_expr_2: dim_of(\dequ::vmrg120_vi2va)
Scope.plot_1_1.y_expr_2: \dequ::vmrg120_vi2va
Scope.plot_1_1.mode_1D_2_1: Line
Scope.plot_1_1.mode_2D_2_1: xz(y)
Scope.plot_1_1.color_2_1: 1
Scope.plot_1_1.marker_2_1: 0
Scope.plot_1_1.step_marker_2_1: 1
Scope.plot_1_1.y_expr_3: \dequ_raw::control.signals:user_1
Scope.plot_1_1.mode_1D_3_1: Line
Scope.plot_1_1.mode_2D_3_1: xz(y)
Scope.plot_1_1.color_3_1: 7
Scope.plot_1_1.marker_3_1: 0
Scope.plot_1_1.step_marker_3_1: 1
Scope.plot_1_1.y_expr_4: \dequ_raw::control.signals:user_54
Scope.plot_1_1.mode_1D_4_1: Line
Scope.plot_1_1.mode_2D_4_1: xz(y)
Scope.plot_1_1.color_4_1: 2
Scope.plot_1_1.marker_4_1: 0
Scope.plot_1_1.step_marker_4_1: 1


Scope.plot_2_1.height: 218
Scope.plot_2_1.grid_mode: 0
Scope.plot_2_1.y_label: "A5"
Scope.plot_2_1.x_log: false
Scope.plot_2_1.y_log: false
Scope.plot_2_1.update_limits: true
Scope.plot_2_1.palette: Green scale
Scope.plot_2_1.bitShift: 0
Scope.plot_2_1.bitClip: false
Scope.plot_2_1.experiment: RFX
Scope.plot_2_1.num_expr: 4
Scope.plot_2_1.num_shot: 1
Scope.plot_2_1.shot: 15224
Scope.plot_2_1.ymax: 30e3
Scope.plot_2_1.xmin: \RFX::T_START_PM-0.01
Scope.plot_2_1.xmax: \RFX::T_END_RFX
Scope.plot_2_1.title: "Im Corrente Magnetizzante  " //$shotname
Scope.plot_2_1.global_defaults: 148225
Scope.plot_2_1.x_expr_1: dim_of(\A05BL05_ID01VA)
Scope.plot_2_1.y_expr_1: \A05BL05_ID01VA+ \A05BL05_ID02VA|||+ \A06BL06_ID01VA + \A06BL06_ID02VA|||+ \A07BL07_ID01VA + \A07BL07_ID02VA|||+ \A08BL08_ID01VA + \A08BL08_ID02VA
Scope.plot_2_1.mode_1D_1_1: Line
Scope.plot_2_1.mode_2D_1_1: xz(y)
Scope.plot_2_1.color_1_1: 7
Scope.plot_2_1.marker_1_1: 0
Scope.plot_2_1.step_marker_1_1: 1
Scope.plot_2_1.x_expr_2: dim_of(\PBMC01_IM01VA)
Scope.plot_2_1.y_expr_2: (\PBMC01_IM01VA + \PBMC02_IM01VA + \PBMC03_IM01VA +\PBMC04_IM01VA ) / 4
Scope.plot_2_1.mode_1D_2_1: Line
Scope.plot_2_1.mode_2D_2_1: xz(y)
Scope.plot_2_1.color_2_1: 1
Scope.plot_2_1.marker_2_1: 0
Scope.plot_2_1.step_marker_2_1: 1
Scope.plot_2_1.x_expr_3: (GETNCI(\EDA1::CONTROL.PARAMETERS:PAR26_VAL, "ON") AND 1) ? \EDA1::CONTROL.PARAMETERS:PAR25_VAL :  [\T_START_PM, \T_STOP_PM]
Scope.plot_2_1.y_expr_3: ((GETNCI(\EDA1::CONTROL.PARAMETERS:PAR26_VAL, "ON") AND 1) ? RfxUnitNumber(\RFX::PM_SETUP:UNITS, 'A') * \EDA1::CONTROL.PARAMETERS:PAR26_VAL * AAGain(\RFX::POLOIDAL:PM_CONTROL, \RFX::POLOIDAL:PM_CONFIG): [0,0])|||
Scope.plot_2_1.mode_1D_3_1: Line
Scope.plot_2_1.mode_2D_3_1: xz(y)
Scope.plot_2_1.color_3_1: 5
Scope.plot_2_1.marker_3_1: 0
Scope.plot_2_1.step_marker_3_1: 1
Scope.plot_2_1.x_expr_4: [\RFX::T_START_PM-0.01, \RFX::T_STOP_PM+2.4]
Scope.plot_2_1.y_expr_4: [30000, 30000]|||+ \A06BL06_ID01VA + \A06BL06_ID02VA|||+ \A07BL07_ID01VA + \A07BL07_ID02VA|||+ \A08BL08_ID01VA + \A08BL08_ID02VA
Scope.plot_2_1.mode_1D_4_1: Line
Scope.plot_2_1.mode_2D_4_1: xz(y)
Scope.plot_2_1.color_4_1: 10
Scope.plot_2_1.marker_4_1: 0
Scope.plot_2_1.step_marker_4_1: 1


Scope.plot_3_1.height: 218
Scope.plot_3_1.grid_mode: 0
Scope.plot_3_1.x_log: false
Scope.plot_3_1.y_log: false
Scope.plot_3_1.update_limits: true
Scope.plot_3_1.palette: Green scale
Scope.plot_3_1.bitShift: 0
Scope.plot_3_1.bitClip: false
Scope.plot_3_1.num_expr: 6
Scope.plot_3_1.num_shot: 1
Scope.plot_3_1.xmin: \RFX::T_INSRT_PTCB_1-0.01
Scope.plot_3_1.xmax: \RFX::T_INSRT_PTCB_1 + 0.1
Scope.plot_3_1.title: "Vr   Tensione ai capi della resistenza di trasferimento"   //$shotname
Scope.plot_3_1.global_defaults: 184193
Scope.plot_3_1.y_expr_1: -\PTRB01_UR01VA
Scope.plot_3_1.mode_1D_1_1: Line
Scope.plot_3_1.mode_2D_1_1: xz(y)
Scope.plot_3_1.color_1_1: 1
Scope.plot_3_1.marker_1_1: 0
Scope.plot_3_1.step_marker_1_1: 1
Scope.plot_3_1.y_expr_2: -\PTRB02_UR01VA
Scope.plot_3_1.mode_1D_2_1: Line
Scope.plot_3_1.mode_2D_2_1: xz(y)
Scope.plot_3_1.color_2_1: 1
Scope.plot_3_1.marker_2_1: 0
Scope.plot_3_1.step_marker_2_1: 1
Scope.plot_3_1.y_expr_3: -\PTRB03_UR01VA
Scope.plot_3_1.mode_1D_3_1: Line
Scope.plot_3_1.mode_2D_3_1: xz(y)
Scope.plot_3_1.color_3_1: 1
Scope.plot_3_1.marker_3_1: 0
Scope.plot_3_1.step_marker_3_1: 1
Scope.plot_3_1.y_expr_4: -\PTRB04_UR01VA
Scope.plot_3_1.mode_1D_4_1: Line
Scope.plot_3_1.mode_2D_4_1: xz(y)
Scope.plot_3_1.color_4_1: 1
Scope.plot_3_1.marker_4_1: 0
Scope.plot_3_1.step_marker_4_1: 1
Scope.plot_3_1.x_expr_5: [-1,1]
Scope.plot_3_1.y_expr_5: [35000, 35000]
Scope.plot_3_1.mode_1D_5_1: Line
Scope.plot_3_1.mode_2D_5_1: xz(y)
Scope.plot_3_1.color_5_1: 10
Scope.plot_3_1.marker_5_1: 0
Scope.plot_3_1.step_marker_5_1: 1
Scope.plot_3_1.x_expr_6: dim_of(\PBMC01_IM01VA )
Scope.plot_3_1.y_expr_6: (|||   (\PBMC01_IM01VA + \PBMC02_IM01VA + \PBMC03_IM01VA +\PBMC04_IM01VA ) / 4 |||   + (\PBMC51_IF01VA + \PBMC52_IF01VA + \PBMC53_IF01VA + \PBMC54_IF01VA||| + \PBMC55_IF01VA + \PBMC56_IF01VA + \PBMC57_IF01VA + \PBMC58_IF01VA) / 4|||)||| * \RFX::P_CONFIG:R_TRANSFER
Scope.plot_3_1.mode_1D_6_1: Line
Scope.plot_3_1.mode_2D_6_1: xz(y)
Scope.plot_3_1.color_6_1: 7
Scope.plot_3_1.marker_6_1: 0
Scope.plot_3_1.step_marker_6_1: 1


Scope.plot_4_1.height: 218
Scope.plot_4_1.grid_mode: 0
Scope.plot_4_1.y_label: "   "
Scope.plot_4_1.x_log: false
Scope.plot_4_1.y_log: false
Scope.plot_4_1.update_limits: true
Scope.plot_4_1.palette: Green scale
Scope.plot_4_1.bitShift: 0
Scope.plot_4_1.bitClip: false
Scope.plot_4_1.experiment: rfx
Scope.plot_4_1.num_expr: 4
Scope.plot_4_1.num_shot: 1
Scope.plot_4_1.ymin: -0.2
Scope.plot_4_1.ymax: 2
Scope.plot_4_1.xmin: \RFX::T_START_GP-0.01
Scope.plot_4_1.xmax: \RFX::T_STOP_GP+0.01
Scope.plot_4_1.title: "immissione gas [mbar*10^-3] & Vrif [V/100]  "//$shotname
Scope.plot_4_1.global_defaults: 49408
Scope.plot_4_1.y_expr_1: \EDAV::VPRESS_01
Scope.plot_4_1.mode_1D_1_1: Line
Scope.plot_4_1.mode_2D_1_1: xz(y)
Scope.plot_4_1.color_1_1: 1
Scope.plot_4_1.marker_1_1: 0
Scope.plot_4_1.step_marker_1_1: 1
Scope.plot_4_1.y_expr_2: \EDAV::VPRESS_02
Scope.plot_4_1.mode_1D_2_1: Line
Scope.plot_4_1.mode_2D_2_1: xz(y)
Scope.plot_4_1.color_2_1: 0
Scope.plot_4_1.marker_2_1: 0
Scope.plot_4_1.step_marker_2_1: 1
Scope.plot_4_1.y_expr_3: \edav::cadh_1.channel_3:data*0.35
Scope.plot_4_1.mode_1D_3_1: Line
Scope.plot_4_1.mode_2D_3_1: xz(y)
Scope.plot_4_1.color_3_1: 10
Scope.plot_4_1.marker_3_1: 0
Scope.plot_4_1.step_marker_3_1: 1
Scope.plot_4_1.y_expr_4: \edav::cadh_1.channel_4:data*0.30
Scope.plot_4_1.mode_1D_4_1: Line
Scope.plot_4_1.mode_2D_4_1: xz(y)
Scope.plot_4_1.color_4_1: 5
Scope.plot_4_1.marker_4_1: 0
Scope.plot_4_1.step_marker_4_1: 1
Scope.rows_in_column_2: 4


Scope.plot_1_2.height: 218
Scope.plot_1_2.grid_mode: 0
Scope.plot_1_2.x_log: false
Scope.plot_1_2.y_log: false
Scope.plot_1_2.update_limits: true
Scope.plot_1_2.palette: Green scale
Scope.plot_1_2.bitShift: 0
Scope.plot_1_2.bitClip: false
Scope.plot_1_2.num_expr: 9
Scope.plot_1_2.num_shot: 1
Scope.plot_1_2.shot: 0
Scope.plot_1_2.ymax: 3500
Scope.plot_1_2.xmin: \RFX::T_START_TF-0.01
Scope.plot_1_2.xmax: \RFX::T_STOP_INV_TC_REF+0.01
Scope.plot_1_2.title: "It Correnti gruppo 1 settori tor. 1 - 3 e 10 - 12   "//$shotname
Scope.plot_1_2.global_defaults: 184193
Scope.plot_1_2.y_expr_1: -\TBMC01_IG01VA
Scope.plot_1_2.mode_1D_1_1: Line
Scope.plot_1_2.mode_2D_1_1: xz(y)
Scope.plot_1_2.color_1_1: 1
Scope.plot_1_2.marker_1_1: 0
Scope.plot_1_2.step_marker_1_1: 1
Scope.plot_1_2.y_expr_2: -\TBMC02_IG01VA
Scope.plot_1_2.mode_1D_2_1: Line
Scope.plot_1_2.mode_2D_2_1: xz(y)
Scope.plot_1_2.color_2_1: 1
Scope.plot_1_2.marker_2_1: 0
Scope.plot_1_2.step_marker_2_1: 1
Scope.plot_1_2.y_expr_3: -\TBMC03_IG01VA
Scope.plot_1_2.mode_1D_3_1: Line
Scope.plot_1_2.mode_2D_3_1: xz(y)
Scope.plot_1_2.color_3_1: 1
Scope.plot_1_2.marker_3_1: 0
Scope.plot_1_2.step_marker_3_1: 1
Scope.plot_1_2.y_expr_4: -\TBMC10_IG01VA
Scope.plot_1_2.mode_1D_4_1: Line
Scope.plot_1_2.mode_2D_4_1: xz(y)
Scope.plot_1_2.color_4_1: 1
Scope.plot_1_2.marker_4_1: 0
Scope.plot_1_2.step_marker_4_1: 1
Scope.plot_1_2.y_expr_5: -\TBMC11_IG01VA
Scope.plot_1_2.mode_1D_5_1: Line
Scope.plot_1_2.mode_2D_5_1: xz(y)
Scope.plot_1_2.color_5_1: 1
Scope.plot_1_2.marker_5_1: 0
Scope.plot_1_2.step_marker_5_1: 1
Scope.plot_1_2.y_expr_6: -\TBMC12_IG01VA
Scope.plot_1_2.mode_1D_6_1: Line
Scope.plot_1_2.mode_2D_6_1: xz(y)
Scope.plot_1_2.color_6_1: 1
Scope.plot_1_2.marker_6_1: 0
Scope.plot_1_2.step_marker_6_1: 1
Scope.plot_1_2.x_expr_7: (GETNCI(\EDA1::CONTROL.PARAMETERS:PAR34_VAL, "ON") AND 1) ? \EDA1::CONTROL.PARAMETERS:PAR33_VAL :  [\T_START_TF, \T_STOP_TF]
Scope.plot_1_2.y_expr_7: (GETNCI(\EDA1::CONTROL.PARAMETERS:PAR34_VAL, "ON") AND 1) ? \EDA1::CONTROL.PARAMETERS:PAR34_VAL * AAGain(\RFX::TOROIDAL:TF_CONTROL, \RFX::TOROIDAL:TF_CONFIG): [0,0]
Scope.plot_1_2.mode_1D_7_1: Line
Scope.plot_1_2.mode_2D_7_1: xz(y)
Scope.plot_1_2.color_7_1: 5
Scope.plot_1_2.marker_7_1: 0
Scope.plot_1_2.step_marker_7_1: 1
Scope.plot_1_2.x_expr_8: [\RFX::T_START_TF-0.01, \RFX::T_STOP_TF+0.01]
Scope.plot_1_2.y_expr_8: [12000, 12000]
Scope.plot_1_2.mode_1D_8_1: Line
Scope.plot_1_2.mode_2D_8_1: xz(y)
Scope.plot_1_2.color_8_1: 10
Scope.plot_1_2.marker_8_1: 0
Scope.plot_1_2.step_marker_8_1: 1
Scope.plot_1_2.y_expr_9: getnci(\RFX::T_START_INV_TC, "STATE" ) == 0  ?  \RFX::INVERTER_SETUP.CHANNEL_1:OUT_SIGNAL  : build_signal([0,0],,[\RFX::T_START_INV_TC, \RFX::T_STOP_INV_TC])
Scope.plot_1_2.mode_1D_9_1: Line
Scope.plot_1_2.mode_2D_9_1: xz(y)
Scope.plot_1_2.color_9_1: 5
Scope.plot_1_2.marker_9_1: 0
Scope.plot_1_2.step_marker_9_1: 1


Scope.plot_2_2.height: 218
Scope.plot_2_2.grid_mode: 0
Scope.plot_2_2.x_log: false
Scope.plot_2_2.y_log: false
Scope.plot_2_2.update_limits: true
Scope.plot_2_2.palette: Green scale
Scope.plot_2_2.bitShift: 0
Scope.plot_2_2.bitClip: false
Scope.plot_2_2.num_expr: 9
Scope.plot_2_2.num_shot: 1
Scope.plot_2_2.shot: 0
Scope.plot_2_2.ymax: 3500
Scope.plot_2_2.xmin: \RFX::T_START_TF-0.01
Scope.plot_2_2.xmax: \RFX::T_STOP_INV_TC_REF+0.01
Scope.plot_2_2.title: "It Correnti gruppo 2 settori tor  4 - 9 "//$shotname
Scope.plot_2_2.global_defaults: 184193
Scope.plot_2_2.x_expr_1: dim_of(\TBMC07_IG01VA)
Scope.plot_2_2.y_expr_1: -\TBMC07_IG01VA
Scope.plot_2_2.mode_1D_1_1: Line
Scope.plot_2_2.mode_2D_1_1: xz(y)
Scope.plot_2_2.color_1_1: 1
Scope.plot_2_2.marker_1_1: 0
Scope.plot_2_2.step_marker_1_1: 1
Scope.plot_2_2.x_expr_2: dim_of(\TBMC08_IG01VA)
Scope.plot_2_2.y_expr_2: -\TBMC08_IG01VA
Scope.plot_2_2.mode_1D_2_1: Line
Scope.plot_2_2.mode_2D_2_1: xz(y)
Scope.plot_2_2.color_2_1: 1
Scope.plot_2_2.marker_2_1: 0
Scope.plot_2_2.step_marker_2_1: 1
Scope.plot_2_2.x_expr_3: dim_of(\TBMC09_IG01VA)
Scope.plot_2_2.y_expr_3: -\TBMC09_IG01VA
Scope.plot_2_2.mode_1D_3_1: Line
Scope.plot_2_2.mode_2D_3_1: xz(y)
Scope.plot_2_2.color_3_1: 1
Scope.plot_2_2.marker_3_1: 0
Scope.plot_2_2.step_marker_3_1: 1
Scope.plot_2_2.x_expr_4: dim_of(\TBMC10_IG01VA)
Scope.plot_2_2.y_expr_4: -\TBMC04_IG01VA
Scope.plot_2_2.mode_1D_4_1: Line
Scope.plot_2_2.mode_2D_4_1: xz(y)
Scope.plot_2_2.color_4_1: 1
Scope.plot_2_2.marker_4_1: 0
Scope.plot_2_2.step_marker_4_1: 1
Scope.plot_2_2.x_expr_5: dim_of(\TBMC11_IG01VA)
Scope.plot_2_2.y_expr_5: -\TBMC05_IG01VA
Scope.plot_2_2.mode_1D_5_1: Line
Scope.plot_2_2.mode_2D_5_1: xz(y)
Scope.plot_2_2.color_5_1: 1
Scope.plot_2_2.marker_5_1: 0
Scope.plot_2_2.step_marker_5_1: 1
Scope.plot_2_2.x_expr_6: dim_of(\TBMC12_IG01VA)
Scope.plot_2_2.y_expr_6: -\TBMC06_IG01VA
Scope.plot_2_2.mode_1D_6_1: Line
Scope.plot_2_2.mode_2D_6_1: xz(y)
Scope.plot_2_2.color_6_1: 1
Scope.plot_2_2.marker_6_1: 0
Scope.plot_2_2.step_marker_6_1: 1
Scope.plot_2_2.x_expr_7: (GETNCI(\EDA1::CONTROL.PARAMETERS:PAR34_VAL, "ON") AND 1) ? \EDA1::CONTROL.PARAMETERS:PAR33_VAL:  [\T_START_TF, \T_STOP_TF]
Scope.plot_2_2.y_expr_7: (GETNCI(\EDA1::CONTROL.PARAMETERS:PAR34_VAL, "ON") AND 1) ? \EDA1::CONTROL.PARAMETERS:PAR34_VAL * AAGain(\RFX::TOROIDAL:TF_CONTROL, \RFX::TOROIDAL:TF_CONFIG): [0,0]
Scope.plot_2_2.mode_1D_7_1: Line
Scope.plot_2_2.mode_2D_7_1: xz(y)
Scope.plot_2_2.color_7_1: 5
Scope.plot_2_2.marker_7_1: 0
Scope.plot_2_2.step_marker_7_1: 1
Scope.plot_2_2.x_expr_8: [\RFX::T_START_TF-0.01, \RFX::T_STOP_TF+0.01]
Scope.plot_2_2.y_expr_8: [12000, 12000]
Scope.plot_2_2.mode_1D_8_1: Line
Scope.plot_2_2.mode_2D_8_1: xz(y)
Scope.plot_2_2.color_8_1: 10
Scope.plot_2_2.marker_8_1: 0
Scope.plot_2_2.step_marker_8_1: 1
Scope.plot_2_2.y_expr_9: getnci(\RFX::T_START_INV_TC, "STATE" ) == 0  ?  \RFX::INVERTER_SETUP.CHANNEL_7:OUT_SIGNAL  : build_signal([0,0],,[\RFX::T_START_INV_TC, \RFX::T_STOP_INV_TC])
Scope.plot_2_2.mode_1D_9_1: Line
Scope.plot_2_2.mode_2D_9_1: xz(y)
Scope.plot_2_2.color_9_1: 5
Scope.plot_2_2.marker_9_1: 0
Scope.plot_2_2.step_marker_9_1: 1


Scope.plot_3_2.height: 218
Scope.plot_3_2.grid_mode: 0
Scope.plot_3_2.x_label: "t"
Scope.plot_3_2.x_log: false
Scope.plot_3_2.y_log: false
Scope.plot_3_2.update_limits: true
Scope.plot_3_2.palette: Green scale
Scope.plot_3_2.bitShift: 0
Scope.plot_3_2.bitClip: false
Scope.plot_3_2.experiment: RFX
Scope.plot_3_2.num_expr: 5
Scope.plot_3_2.num_shot: 1
Scope.plot_3_2.shot: 0
Scope.plot_3_2.xmin: \RFX::T_START_PC-0.01
Scope.plot_3_2.xmax: \RFX::T_STOP_PC+0.04
Scope.plot_3_2.title: "Vpcat  Tensioni conv. PCAT "//PCAT_label() //" "//$shotname
Scope.plot_3_2.global_defaults: 182145
Scope.plot_3_2.label_1: "A1"
Scope.plot_3_2.y_expr_1: PCAT_voltage(\A01BL01_UD01VA, \A01BL01_UD02VA)
Scope.plot_3_2.mode_1D_1_1: Line
Scope.plot_3_2.mode_2D_1_1: xz(y)
Scope.plot_3_2.color_1_1: 1
Scope.plot_3_2.marker_1_1: 0
Scope.plot_3_2.step_marker_1_1: 1
Scope.plot_3_2.label_2: "A2"
Scope.plot_3_2.y_expr_2: PCAT_voltage(\A02BL02_UD01VA , \A02BL02_UD02VA)
Scope.plot_3_2.mode_1D_2_1: Line
Scope.plot_3_2.mode_2D_2_1: xz(y)
Scope.plot_3_2.color_2_1: 1
Scope.plot_3_2.marker_2_1: 0
Scope.plot_3_2.step_marker_2_1: 1
Scope.plot_3_2.label_3: "A3"
Scope.plot_3_2.y_expr_3: PCAT_voltage(\A03BL03_UD01VA , \A03BL03_UD02VA)
Scope.plot_3_2.mode_1D_3_1: Line
Scope.plot_3_2.mode_2D_3_1: xz(y)
Scope.plot_3_2.color_3_1: 1
Scope.plot_3_2.marker_3_1: 0
Scope.plot_3_2.step_marker_3_1: 1
Scope.plot_3_2.label_4: "A4"
Scope.plot_3_2.y_expr_4: PCAT_voltage(\A04BL04_UD01VA, \A04BL04_UD02VA)
Scope.plot_3_2.mode_1D_4_1: Line
Scope.plot_3_2.mode_2D_4_1: xz(y)
Scope.plot_3_2.color_4_1: 1
Scope.plot_3_2.marker_4_1: 0
Scope.plot_3_2.step_marker_4_1: 1
Scope.plot_3_2.label_5: "A1"
Scope.plot_3_2.x_expr_5: (GETNCI(\EDA1::CONTROL.PARAMETERS:PAR18_VAL, "ON") AND 1) ? \EDA1::CONTROL.PARAMETERS:PAR17_VAL :  [\T_START_PC, \T_STOP_PC]
Scope.plot_3_2.y_expr_5: ((GETNCI(\EDA1::CONTROL.PARAMETERS:PAR18_VAL, "ON") AND 1) ? \EDA1::CONTROL.PARAMETERS:PAR18_VAL * AAGain(\RFX::POLOIDAL:PC_CONTROL, \RFX::POLOIDAL:PC_CONFIG): [0,0])
Scope.plot_3_2.mode_1D_5_1: Line
Scope.plot_3_2.mode_2D_5_1: xz(y)
Scope.plot_3_2.color_5_1: 5
Scope.plot_3_2.marker_5_1: 0
Scope.plot_3_2.step_marker_5_1: 1


Scope.plot_4_2.height: 218
Scope.plot_4_2.grid_mode: 0
Scope.plot_4_2.x_label: "t"
Scope.plot_4_2.x_log: false
Scope.plot_4_2.y_log: false
Scope.plot_4_2.update_limits: true
Scope.plot_4_2.palette: Green scale
Scope.plot_4_2.bitShift: 0
Scope.plot_4_2.bitClip: false
Scope.plot_4_2.experiment: RFX
Scope.plot_4_2.num_expr: 13
Scope.plot_4_2.num_shot: 1
Scope.plot_4_2.shot: 0
Scope.plot_4_2.ymin: -100
Scope.plot_4_2.xmin: \RFX::T_START_CHOP_TC
Scope.plot_4_2.xmax: \RFX::T_STOP_CHOP_TC
Scope.plot_4_2.title: "Vtccb tensioni banchi condensatori toroidale " //$shotname
Scope.plot_4_2.global_defaults: 165761
Scope.plot_4_2.y_expr_1: \TCCH01_UD01VA
Scope.plot_4_2.mode_1D_1_1: Line
Scope.plot_4_2.mode_2D_1_1: xz(y)
Scope.plot_4_2.color_1_1: 1
Scope.plot_4_2.marker_1_1: 0
Scope.plot_4_2.step_marker_1_1: 1
Scope.plot_4_2.y_expr_2: \TCCH02_UD01VA
Scope.plot_4_2.mode_1D_2_1: Line
Scope.plot_4_2.mode_2D_2_1: xz(y)
Scope.plot_4_2.color_2_1: 1
Scope.plot_4_2.marker_2_1: 0
Scope.plot_4_2.step_marker_2_1: 1
Scope.plot_4_2.y_expr_3: \TCCH03_UD01VA
Scope.plot_4_2.mode_1D_3_1: Line
Scope.plot_4_2.mode_2D_3_1: xz(y)
Scope.plot_4_2.color_3_1: 1
Scope.plot_4_2.marker_3_1: 0
Scope.plot_4_2.step_marker_3_1: 1
Scope.plot_4_2.y_expr_4: \TCCH04_UD01VA
Scope.plot_4_2.mode_1D_4_1: Line
Scope.plot_4_2.mode_2D_4_1: xz(y)
Scope.plot_4_2.color_4_1: 1
Scope.plot_4_2.marker_4_1: 0
Scope.plot_4_2.step_marker_4_1: 1
Scope.plot_4_2.y_expr_5: \TCCH05_UD01VA
Scope.plot_4_2.mode_1D_5_1: Line
Scope.plot_4_2.mode_2D_5_1: xz(y)
Scope.plot_4_2.color_5_1: 1
Scope.plot_4_2.marker_5_1: 0
Scope.plot_4_2.step_marker_5_1: 1
Scope.plot_4_2.y_expr_6: \TCCH06_UD01VA
Scope.plot_4_2.mode_1D_6_1: Line
Scope.plot_4_2.mode_2D_6_1: xz(y)
Scope.plot_4_2.color_6_1: 1
Scope.plot_4_2.marker_6_1: 0
Scope.plot_4_2.step_marker_6_1: 1
Scope.plot_4_2.y_expr_7: \TCCH07_UD01VA
Scope.plot_4_2.mode_1D_7_1: Line
Scope.plot_4_2.mode_2D_7_1: xz(y)
Scope.plot_4_2.color_7_1: 1
Scope.plot_4_2.marker_7_1: 0
Scope.plot_4_2.step_marker_7_1: 1
Scope.plot_4_2.y_expr_8: \TCCH08_UD01VA
Scope.plot_4_2.mode_1D_8_1: Line
Scope.plot_4_2.mode_2D_8_1: xz(y)
Scope.plot_4_2.color_8_1: 1
Scope.plot_4_2.marker_8_1: 0
Scope.plot_4_2.step_marker_8_1: 1
Scope.plot_4_2.y_expr_9: \TCCH09_UD01VA
Scope.plot_4_2.mode_1D_9_1: Line
Scope.plot_4_2.mode_2D_9_1: xz(y)
Scope.plot_4_2.color_9_1: 1
Scope.plot_4_2.marker_9_1: 0
Scope.plot_4_2.step_marker_9_1: 1
Scope.plot_4_2.y_expr_10: \TCCH10_UD01VA
Scope.plot_4_2.mode_1D_10_1: Line
Scope.plot_4_2.mode_2D_10_1: xz(y)
Scope.plot_4_2.color_10_1: 1
Scope.plot_4_2.marker_10_1: 0
Scope.plot_4_2.step_marker_10_1: 1
Scope.plot_4_2.y_expr_11: \TCCH11_UD01VA
Scope.plot_4_2.mode_1D_11_1: Line
Scope.plot_4_2.mode_2D_11_1: xz(y)
Scope.plot_4_2.color_11_1: 1
Scope.plot_4_2.marker_11_1: 0
Scope.plot_4_2.step_marker_11_1: 1
Scope.plot_4_2.y_expr_12: \TCCH12_UD01VA
Scope.plot_4_2.mode_1D_12_1: Line
Scope.plot_4_2.mode_2D_12_1: xz(y)
Scope.plot_4_2.color_12_1: 1
Scope.plot_4_2.marker_12_1: 0
Scope.plot_4_2.step_marker_12_1: 1
Scope.plot_4_2.x_expr_13: [\RFX::T_START_CHOP_TC, \RFX::T_STOP_CHOP_TC]
Scope.plot_4_2.y_expr_13: [2000, 2000]
Scope.plot_4_2.mode_1D_13_1: Line
Scope.plot_4_2.mode_2D_13_1: xz(y)
Scope.plot_4_2.color_13_1: 10
Scope.plot_4_2.marker_13_1: 0
Scope.plot_4_2.step_marker_13_1: 1
Scope.rows_in_column_3: 5


Scope.plot_1_3.height: 196
Scope.plot_1_3.grid_mode: 0
Scope.plot_1_3.x_log: false
Scope.plot_1_3.y_log: false
Scope.plot_1_3.update_limits: true
Scope.plot_1_3.palette: Green scale
Scope.plot_1_3.bitShift: 0
Scope.plot_1_3.bitClip: false
Scope.plot_1_3.num_expr: 3
Scope.plot_1_3.num_shot: 1
Scope.plot_1_3.ymin: \RFX::T_INSRT_PTCB_1-0.01
Scope.plot_1_3.ymax: 0.015
Scope.plot_1_3.xmin: \RFX::T_INSRT_PTCB_1-0.01
Scope.plot_1_3.xmax: \RFX::T_STOP_PC+0.08
Scope.plot_1_3.title: "deltaH         "//$shotname
Scope.plot_1_3.global_defaults: 135041
Scope.plot_1_3.y_expr_1: \A::EQFLU_DELTAH
Scope.plot_1_3.mode_1D_1_1: Line
Scope.plot_1_3.mode_2D_1_1: xz(y)
Scope.plot_1_3.color_1_1: 1
Scope.plot_1_3.marker_1_1: 0
Scope.plot_1_3.step_marker_1_1: 1
Scope.plot_1_3.y_expr_2: \dequ_raw::control.signals:user_52
Scope.plot_1_3.mode_1D_2_1: Line
Scope.plot_1_3.mode_2D_2_1: xz(y)
Scope.plot_1_3.color_2_1: 10
Scope.plot_1_3.marker_2_1: 0
Scope.plot_1_3.step_marker_2_1: 1
Scope.plot_1_3.y_expr_3: \RFX::AXI_CONTROL.REF_DELTA_H:WAVE
Scope.plot_1_3.mode_1D_3_1: Line
Scope.plot_1_3.mode_2D_3_1: xz(y)
Scope.plot_1_3.color_3_1: 5
Scope.plot_1_3.marker_3_1: 0
Scope.plot_1_3.step_marker_3_1: 1


Scope.plot_2_3.height: 216
Scope.plot_2_3.grid_mode: 0
Scope.plot_2_3.x_label: "t"
Scope.plot_2_3.x_log: false
Scope.plot_2_3.y_log: false
Scope.plot_2_3.update_limits: true
Scope.plot_2_3.palette: Green scale
Scope.plot_2_3.bitShift: 0
Scope.plot_2_3.bitClip: false
Scope.plot_2_3.experiment: RFX
Scope.plot_2_3.num_expr: 9
Scope.plot_2_3.num_shot: 1
Scope.plot_2_3.shot: 0
Scope.plot_2_3.ymin: -100
Scope.plot_2_3.xmin: \RFX::T_INSRT_PTCB_1-.1
Scope.plot_2_3.xmax: \RFX::T_STOP_PV+0.04
Scope.plot_2_3.title: "If  " //$shotname
Scope.plot_2_3.global_defaults: 171905
Scope.plot_2_3.label_1: "IF1 "
Scope.plot_2_3.x_expr_1: dim_of(\PBMC51_IF01VA)
Scope.plot_2_3.y_expr_1: -\PBMC51_IF01VA
Scope.plot_2_3.mode_1D_1_1: Line
Scope.plot_2_3.mode_2D_1_1: xz(y)
Scope.plot_2_3.color_1_1: 1
Scope.plot_2_3.marker_1_1: 0
Scope.plot_2_3.step_marker_1_1: 1
Scope.plot_2_3.label_2: "IF2 "
Scope.plot_2_3.x_expr_2: dim_of(\PBMC52_IF01VA)
Scope.plot_2_3.y_expr_2: -\PBMC52_IF01VA
Scope.plot_2_3.mode_1D_2_1: Line
Scope.plot_2_3.mode_2D_2_1: xz(y)
Scope.plot_2_3.color_2_1: 4
Scope.plot_2_3.marker_2_1: 0
Scope.plot_2_3.step_marker_2_1: 1
Scope.plot_2_3.label_3: "IF3 "
Scope.plot_2_3.x_expr_3: dim_of(\PBMC53_IF01VA)
Scope.plot_2_3.y_expr_3: -\PBMC53_IF01VA
Scope.plot_2_3.mode_1D_3_1: Line
Scope.plot_2_3.mode_2D_3_1: xz(y)
Scope.plot_2_3.color_3_1: 7
Scope.plot_2_3.marker_3_1: 0
Scope.plot_2_3.step_marker_3_1: 1
Scope.plot_2_3.label_4: "IF4 "
Scope.plot_2_3.x_expr_4: dim_of(\PBMC54_IF01VA)
Scope.plot_2_3.y_expr_4: -\PBMC54_IF01VA
Scope.plot_2_3.mode_1D_4_1: Line
Scope.plot_2_3.mode_2D_4_1: xz(y)
Scope.plot_2_3.color_4_1: 8
Scope.plot_2_3.marker_4_1: 0
Scope.plot_2_3.step_marker_4_1: 1
Scope.plot_2_3.label_5: "IF 5 "
Scope.plot_2_3.x_expr_5: dim_of(\PBMC55_IF01VA)
Scope.plot_2_3.y_expr_5: -\PBMC55_IF01VA
Scope.plot_2_3.mode_1D_5_1: Line
Scope.plot_2_3.mode_2D_5_1: xz(y)
Scope.plot_2_3.color_5_1: 9
Scope.plot_2_3.marker_5_1: 0
Scope.plot_2_3.step_marker_5_1: 1
Scope.plot_2_3.label_6: "IF6 "
Scope.plot_2_3.x_expr_6: dim_of(\PBMC56_IF01VA)
Scope.plot_2_3.y_expr_6: -\PBMC56_IF01VA
Scope.plot_2_3.mode_1D_6_1: Line
Scope.plot_2_3.mode_2D_6_1: xz(y)
Scope.plot_2_3.color_6_1: 2
Scope.plot_2_3.marker_6_1: 0
Scope.plot_2_3.step_marker_6_1: 1
Scope.plot_2_3.label_7: "IF7 "
Scope.plot_2_3.x_expr_7: dim_of(\PBMC57_IF01VA)
Scope.plot_2_3.y_expr_7: -\PBMC57_IF01VA
Scope.plot_2_3.mode_1D_7_1: Line
Scope.plot_2_3.mode_2D_7_1: xz(y)
Scope.plot_2_3.color_7_1: 6
Scope.plot_2_3.marker_7_1: 0
Scope.plot_2_3.step_marker_7_1: 1
Scope.plot_2_3.label_8: "IF8 "
Scope.plot_2_3.x_expr_8: dim_of(\PBMC58_IF01VA)
Scope.plot_2_3.y_expr_8: -\PBMC58_IF01VA
Scope.plot_2_3.mode_1D_8_1: Line
Scope.plot_2_3.mode_2D_8_1: xz(y)
Scope.plot_2_3.color_8_1: 0
Scope.plot_2_3.marker_8_1: 0
Scope.plot_2_3.step_marker_8_1: 1
Scope.plot_2_3.label_9: "IF imite massimo "
Scope.plot_2_3.x_expr_9: [\RFX::T_START_PV-0.01, \RFX::T_STOP_PV+0.01]
Scope.plot_2_3.y_expr_9: [6000, 6000]
Scope.plot_2_3.mode_1D_9_1: Line
Scope.plot_2_3.mode_2D_9_1: xz(y)
Scope.plot_2_3.color_9_1: 10
Scope.plot_2_3.marker_9_1: 0
Scope.plot_2_3.step_marker_9_1: 1


Scope.plot_3_3.height: 213
Scope.plot_3_3.grid_mode: 0
Scope.plot_3_3.x_log: false
Scope.plot_3_3.y_log: false
Scope.plot_3_3.update_limits: true
Scope.plot_3_3.palette: Green scale
Scope.plot_3_3.bitShift: 0
Scope.plot_3_3.bitClip: false
Scope.plot_3_3.num_expr: 3
Scope.plot_3_3.num_shot: 1
Scope.plot_3_3.ymin: -10
Scope.plot_3_3.ymax: 370
Scope.plot_3_3.xmin: \RFX::T_INSRT_PTCB_1-0.01
Scope.plot_3_3.xmax: \RFX::T_STOP_PC+0.04
Scope.plot_3_3.title: "lock_pos     " //$shotname
Scope.plot_3_3.global_defaults: 135041
Scope.plot_3_3.y_expr_1: \dflu::LOCK_POS
Scope.plot_3_3.mode_1D_1_1: Line
Scope.plot_3_3.mode_2D_1_1: xz(y)
Scope.plot_3_3.color_1_1: 1
Scope.plot_3_3.marker_1_1: 0
Scope.plot_3_3.step_marker_1_1: 1
Scope.plot_3_3.y_expr_2: (360 / (2 * $PI)) * \dflu_raw::control.signals:user_201
Scope.plot_3_3.mode_1D_2_1: Line
Scope.plot_3_3.mode_2D_2_1: xz(y)
Scope.plot_3_3.color_2_1: 10
Scope.plot_3_3.marker_2_1: 0
Scope.plot_3_3.step_marker_2_1: 1
Scope.plot_3_3.x_expr_3: dim_of(\eda3::control.signals:user_108)
Scope.plot_3_3.y_expr_3: (\eda3::control.signals:user_108 * 360 / (2 *$PI)  + 360)  mod  360
Scope.plot_3_3.mode_1D_3_1: Line
Scope.plot_3_3.mode_2D_3_1: xz(y)
Scope.plot_3_3.color_3_1: 5
Scope.plot_3_3.marker_3_1: 0
Scope.plot_3_3.step_marker_3_1: 1


Scope.plot_4_3.height: 147
Scope.plot_4_3.grid_mode: 0
Scope.plot_4_3.x_log: false
Scope.plot_4_3.y_log: false
Scope.plot_4_3.update_limits: true
Scope.plot_4_3.palette: Green scale
Scope.plot_4_3.bitShift: 0
Scope.plot_4_3.bitClip: false
Scope.plot_4_3.default_node: \STC_TR10_1
Scope.plot_4_3.num_expr: 1
Scope.plot_4_3.num_shot: 1
Scope.plot_4_3.ymin: 0
Scope.plot_4_3.xmin: -2
Scope.plot_4_3.xmax: .4
Scope.plot_4_3.title: "Potenza assorbita su sbarre MT [MW]     "//$shotname
Scope.plot_4_3.global_defaults: 134529
Scope.plot_4_3.x_expr_1: DIM_of(\GQSF01_IR01VA)
Scope.plot_4_3.y_expr_1: \GQSF01_IR01VA*\GQSF01_UR01VA+\GQSF01_IS01VA*\GQSF01_US01VA+\GQSF01_IT01VA*\GQSF01_UT01VA+|||\GQSF02_IR01VA*\GQSF02_UR01VA+\GQSF02_IS01VA*\GQSF02_US01VA+\GQSF02_IT01VA*\GQSF02_UT01VA
Scope.plot_4_3.mode_1D_1_1: Line
Scope.plot_4_3.mode_2D_1_1: xz(y)
Scope.plot_4_3.color_1_1: 0
Scope.plot_4_3.marker_1_1: 0
Scope.plot_4_3.step_marker_1_1: 1


Scope.plot_5_3.height: 101
Scope.plot_5_3.grid_mode: 0
Scope.plot_5_3.x_log: false
Scope.plot_5_3.y_log: false
Scope.plot_5_3.update_limits: true
Scope.plot_5_3.palette: Green scale
Scope.plot_5_3.bitShift: 0
Scope.plot_5_3.bitClip: false
Scope.plot_5_3.default_node: \STC_TR10_1
Scope.plot_5_3.num_expr: 1
Scope.plot_5_3.num_shot: 1
Scope.plot_5_3.ymin: 0
Scope.plot_5_3.ymax: 7
Scope.plot_5_3.xmin: \RFX::T_START_RFX
Scope.plot_5_3.xmax: \RFX::T_END_RFX
Scope.plot_5_3.title: "Intervento SGPR CCT      "//$shotname
Scope.plot_5_3.global_defaults: 134529
Scope.plot_5_3.y_expr_1: .CHANNEL_09:DATA
Scope.plot_5_3.mode_1D_1_1: Line
Scope.plot_5_3.mode_2D_1_1: xz(y)
Scope.plot_5_3.color_1_1: 1
Scope.plot_5_3.marker_1_1: 0
Scope.plot_5_3.step_marker_1_1: 1

Scope.vpane_1: 307
Scope.vpane_2: 663
