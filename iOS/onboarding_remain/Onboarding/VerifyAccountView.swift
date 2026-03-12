//
//  VerifyAccountView.swift
//  onbroading_remain
//
//  Created by Yutong on 3/11/26.
//
import SwiftUI

// MARK: - Screen 4: Verify Account
struct VerifyAccountView: View {
    let phoneNumber: String
    @Binding var path: NavigationPath
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var timeRemaining = 40

    var body: some View {
        VStack(spacing: 0) {
            FruitsHeader()

            VStack(spacing: 24) {
                Text("Verify Account")
                    .font(.custom("DaysOne-Regular", size: 24))
                    .foregroundColor(.ilyOrange)
                    .padding(.top, 16)

                VStack(spacing: 6) {
                    Text("Please enter the code sent to")
                        .font(.custom("Inter_18pt-Regular", size: 15))
                        .foregroundColor(.gray)

                    Text(phoneNumber.isEmpty ? "+1 123 456 8910" : phoneNumber)
                        .font(.custom("DaysOne-Regular", size: 24))
                        .foregroundColor(.black)
                }

                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { i in
                        TextField("", text: $code[i])
                            .frame(width: 36, height: 44)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .font(.system(size: 20))
                            .focused($focusedIndex, equals: i)
                            .onChange(of: code[i]) { _, newVal in
                                if newVal.count > 1 { code[i] = String(newVal.prefix(1)) }
                                if newVal.count == 1 && i < 5 { focusedIndex = i + 1 }
                            }
                            .overlay(
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(.black)
                                    .padding(.top, 40),
                                alignment: .bottom
                            )
                    }
                }

                Button {} label: {
                    Text("Click here to resend code in \(timeRemaining)s")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Button {
                    path.append(AppRoute.termsAndConditions)
                } label: {
                    Text("Verify")
                        .font(.custom("Inter18pt-Regular", size: 17))
                        .foregroundColor(.white)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 14)
                        .background(Color.ilyOrange)
                        .cornerRadius(30)
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
                if timeRemaining > 0 { timeRemaining -= 1 } else { t.invalidate() }
            }
        }
    }
}
