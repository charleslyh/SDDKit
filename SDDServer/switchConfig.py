import sys

print("输入`0`使用有缺陷设置\n输入`1`使用修复设置\nctrl+c结束程序")

try:
	while True:
		ch = sys.stdin.read(1)
		#域的问题 时间紧迫 暂时这么写= =
		if ch == '0':
			fout = open("./config/verifyButtonStateConfig", "w")
			fin = open("./config/verifyButtonDefective", "r")
			content = fin.read()
			fout.write(content)
			fout.close()
			fin.close()
		elif ch == '1':
			fout = open("./config/verifyButtonStateConfig", "w")
			fin = open("./config/verifyButtonFixed", "r")
			content = fin.read()
			fout.write(content)
			fout.close()
			fin.close()
except KeyboardInterrupt:
	if not fout.closed:
		fout.close()