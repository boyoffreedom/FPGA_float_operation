
F_bit = 23
E_bit = 8

in_name = 'add_f1'
out_name = 'sub_shift'

#index = '[2*F_bit+1:F_bit+1]'
index = ''
#该代码用于生成并行优先编码器，用于浮点型减法运算对齐
f = open("encoder.v","w+")
f.write("module encoder(%s,%s);\n\n"%(in_name,out_name))
f.write("parameter E_bit = %d,F_bit = %d;\n\n"%(E_bit,F_bit))
f.write("input wire[%d:0] %s;\noutput reg[%d:0] %s;\n\n"%(F_bit,in_name,E_bit-1,out_name))
f.write("always @(%s) begin\n\tcasex(%s%s)\n"%(in_name,in_name,index))
for i in range(0,F_bit+1):
    f.write("\t\t%d\'b"%(F_bit+1))
    a = ""
    for j in range(0,i):
        a += "0"
    a+="1"
    for j in range(i,F_bit):
        a += "x"
    f.write(a)
    f.write(": %s=%d'h%d"%(out_name,E_bit-1,i))
    f.write(";\n")
f.write("\t\tdefault: %s = %d'h0;\n"%(out_name,E_bit-1))
f.write("\tendcase\nend\nendmodule\n\n")
f.close()
