//
//  ContentView.swift
//  TimeCalculator
//
//  Created by 颜宇辰 on 2026/2/16.
//

import SwiftUI

struct ContentView: View {
    @State private var display = "0"
    @State private var expressionDisplay = ""  // 计算过程显示
    @State private var currentNumber = ""
    @State private var firstNumber: Double = 0
    @State private var secondNumber: Double = 0
    @State private var operation = ""
    @State private var waitingForSecondNumber = false
    @State private var timeNumber: Double = 0
    @State private var isTimeMode = false
    @State private var presetThirdNumber = ""
    @State private var currentDigitIndex = 0
    @State private var hasCalculated = false  // 标记是否刚计算完
    @State private var sumResult: Double = 0  // 存储第一次计算的结果
    
    let buttons: [[CalculatorButton]] = [
        [.clear, .negative, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equal]
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                
                // 显示屏
                VStack(alignment: .trailing, spacing: 8) {
                    // 计算过程（小字，灰色）
                    if !expressionDisplay.isEmpty {
                        Text(expressionDisplay)
                            .font(.system(size: 28, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    
                    // 当前数字（大字，白色）
                    Text(display)
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // 按钮
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButtonView(button: button) {
                                self.buttonTapped(button)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
    }
    
    func buttonTapped(_ button: CalculatorButton) {
        switch button {
        case .clear:
            clear()
        case .negative:
            toggleSign()
        case .percent:
            percent()
        case .add, .subtract, .multiply, .divide:
            handleOperation(button)
        case .equal:
            calculateResult()
        case .decimal:
            addDecimal()
        default:
            appendNumber(button.rawValue)
        }
    }
    
    func clear() {
        print("🔄 Clear - 重置所有状态")
        display = "0"
        expressionDisplay = ""
        currentNumber = ""
        firstNumber = 0
        secondNumber = 0
        operation = ""
        waitingForSecondNumber = false
        timeNumber = 0
        isTimeMode = false
        presetThirdNumber = ""
        currentDigitIndex = 0
        hasCalculated = false
        sumResult = 0
    }
    
    func toggleSign() {
        if isTimeMode { return }
        if let value = Double(currentNumber.isEmpty ? display : currentNumber) {
            let newValue = value * -1
            currentNumber = String(newValue)
            display = currentNumber
            
            // 更新表达式显示
            if operation != "" {
                expressionDisplay = formatNumber(firstNumber) + operation + formatNumber(newValue)
            }
        }
    }
    
    func percent() {
        if isTimeMode { return }
        if let value = Double(currentNumber.isEmpty ? display : currentNumber) {
            let newValue = value / 100
            currentNumber = String(newValue)
            display = currentNumber
            
            // 更新表达式显示
            if operation != "" {
                expressionDisplay = formatNumber(firstNumber) + operation + formatNumber(newValue)
            }
        }
    }
    
    func addDecimal() {
        if isTimeMode { return }
        if waitingForSecondNumber {
            display = "0."
            currentNumber = "0."
            waitingForSecondNumber = false
        } else if !currentNumber.contains(".") {
            currentNumber += "."
            display = currentNumber
        }
    }
    
    func appendNumber(_ number: String) {
        // 时间模式下，逐位显示预设的第三个数
        if isTimeMode {
            print("⏰ 时间模式 - 用户按了: \(number), 实际显示预设数字的第 \(currentDigitIndex) 位")
            if currentDigitIndex < presetThirdNumber.count {
                let index = presetThirdNumber.index(presetThirdNumber.startIndex, offsetBy: currentDigitIndex)
                let digit = String(presetThirdNumber[index])
                
                print("   显示数字: \(digit) (预设第三个数: \(presetThirdNumber))")
                
                if currentDigitIndex == 0 {
                    currentNumber = digit
                } else {
                    currentNumber += digit
                }
                
                // 显示不带格式化的数字
                display = currentNumber
                
                // 更新表达式显示（使用格式化的数字）
                if let numValue = Double(currentNumber) {
                    expressionDisplay = formatNumber(sumResult) + "+" + formatNumber(numValue)
                }
                
                currentDigitIndex += 1
            } else {
                print("   已显示完所有位数")
            }
            return
        }
        
        if waitingForSecondNumber {
            print("📝 输入数字: \(number) (新数字)")
            currentNumber = number
            display = number
            waitingForSecondNumber = false
            hasCalculated = false  // 开始输入新数字，重置计算标记
            
            // 更新表达式显示
            if operation != "" {
                if let numValue = Double(currentNumber) {
                    expressionDisplay = formatNumber(firstNumber) + operation + formatNumber(numValue)
                }
            }
        } else {
            print("📝 输入数字: \(number) (追加)")
            if display == "0" || display == "错误" {
                currentNumber = number
                display = number
            } else {
                currentNumber += number
                display = currentNumber
            }
            
            // 更新表达式显示
            if operation != "" {
                if let numValue = Double(currentNumber) {
                    expressionDisplay = formatNumber(firstNumber) + operation + formatNumber(numValue)
                }
            }
        }
    }
    
    func handleOperation(_ button: CalculatorButton) {
        if isTimeMode { 
            print("⚠️ 时间模式中，忽略运算符")
            return 
        }
        
        print("➕ 按运算符: \(button.rawValue)")
        
        // 检查是否在计算完成后按加号（触发时间模式）
        if button == .add && hasCalculated {
            print("🎯 触发时间模式！")
            print("   第一个数: \(firstNumber)")
            print("   第二个数: \(secondNumber)")
            
            isTimeMode = true
            timeNumber = getTimeNumber()
            print("   时间数字: \(timeNumber)")
            
            // 计算第三个数 = 时间数字 - 第一个数 - 第二个数
            let thirdNumber = timeNumber - firstNumber - secondNumber
            // 保存未格式化的数字字符串（不带逗号）
            if thirdNumber.truncatingRemainder(dividingBy: 1) == 0 {
                presetThirdNumber = String(format: "%.0f", thirdNumber)
            } else {
                presetThirdNumber = String(thirdNumber)
            }
            print("   预设第三个数: \(presetThirdNumber)")
            
            // 更新表达式显示
            expressionDisplay = formatNumber(sumResult) + "+"
            
            // 清空主显示，准备逐位输入
            display = "0"
            currentNumber = ""
            currentDigitIndex = 0
            return
        }
        
        // 普通运算
        if currentNumber != "" {
            if operation != "" && !waitingForSecondNumber {
                calculateResult()
            }
            firstNumber = Double(currentNumber) ?? 0
            print("   记录数字: \(firstNumber)")
            currentNumber = ""
        }
        
        operation = button.rawValue
        waitingForSecondNumber = true
        hasCalculated = false
        
        // 更新表达式显示
        expressionDisplay = formatNumber(firstNumber) + button.rawValue
    }
    
    func calculateResult() {
        print("🟰 按等号")
        
        if isTimeMode {
            print("⏰ 时间模式计算最终结果")
            // 时间模式下，直接使用预设的第三个数
            let thirdNumber = Double(presetThirdNumber) ?? 0
            let result = firstNumber + secondNumber + thirdNumber
            print("   \(firstNumber) + \(secondNumber) + \(thirdNumber) = \(result)")
            display = formatNumber(result)
            expressionDisplay = ""  // 清空表达式显示
            firstNumber = result
            currentNumber = ""
            operation = ""
            waitingForSecondNumber = true
            isTimeMode = false
            presetThirdNumber = ""
            currentDigitIndex = 0
            hasCalculated = true
            return
        }
        
        if operation == "" { 
            print("   没有运算符，忽略")
            return 
        }
        
        secondNumber = Double(currentNumber) ?? 0
        var result: Double = 0
        
        print("   第一个数: \(firstNumber)")
        print("   运算符: \(operation)")
        print("   第二个数: \(secondNumber)")
        
        switch operation {
        case "+":
            result = firstNumber + secondNumber
        case "-":
            result = firstNumber - secondNumber
        case "×":
            result = firstNumber * secondNumber
        case "÷":
            if secondNumber == 0 {
                display = "错误"
                expressionDisplay = ""
                print("   错误：除以零")
                return
            }
            result = firstNumber / secondNumber
        default:
            return
        }
        
        print("   结果: \(result)")
        display = formatNumber(result)
        expressionDisplay = ""  // 清空表达式显示
        
        // 保存第一个数和第二个数（用于后续的时间模式）
        // firstNumber 和 secondNumber 保持不变
        sumResult = result
        
        currentNumber = ""
        operation = ""
        waitingForSecondNumber = true
        hasCalculated = true  // 标记已计算完成
        
        print("   已标记为计算完成，再按+将触发时间模式")
    }
    
    func getTimeNumber() -> Double {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        let hour = calendar.component(.hour, from: now)
        var minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        
        // 若秒数大于10，分钟加1
        if second > 20 {
            minute += 1
            if minute >= 60 {
                minute = 0
            }
        }
        
        // 格式：月日时分（24小时制）
        // 例如：2月16日22点27分 = 2162227
        let timeString = String(format: "%d%02d%02d%02d", month, day, hour, minute)
        return Double(timeString) ?? 0
    }
    
    func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 8
        
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }
        
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }
}

enum CalculatorButton: String {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case add = "+", subtract = "-", multiply = "×", divide = "÷"
    case equal = "=", clear = "AC", decimal = ".", percent = "%", negative = "+/-"
    
    var backgroundColor: Color {
        switch self {
        case .add, .subtract, .multiply, .divide, .equal:
            return Color.orange
        case .clear, .negative, .percent:
            return Color.gray.opacity(0.5)
        default:
            return Color.gray.opacity(0.3)
        }
    }
}

struct CalculatorButtonView: View {
    let button: CalculatorButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.rawValue)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
                .frame(width: buttonWidth(), height: buttonHeight())
                .background(button.backgroundColor)
                .cornerRadius(buttonWidth() / 2)
        }
    }
    
    func buttonWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 12
        let totalSpacing = spacing * 5
        
        if button == .zero {
            return (screenWidth - totalSpacing - 32) / 4 * 2 + spacing
        }
        
        return (screenWidth - totalSpacing - 32) / 4
    }
    
    func buttonHeight() -> CGFloat {
        return (UIScreen.main.bounds.width - 60 - 48) / 4
    }
}

#Preview {
    ContentView()
}
