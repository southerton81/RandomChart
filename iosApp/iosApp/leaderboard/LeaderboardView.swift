import Foundation
import SwiftUI
import Combine

struct LeaderboardView: View {
    @EnvironmentObject var chartObservable: ChartObservableObject
    @EnvironmentObject var leadersObservable: LeadersObservableObject
    @State private var username: String = ""
    let usernameMaxChars = 30
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                Spacer()
                Text(StringConstants.leaderboardTitle)
                Spacer()
                
                ScrollViewReader { proxy in
                    VStack {
                        List {
                            
                            if !self.leadersObservable.leaderboardUiModel.scores.isEmpty &&
                                !self.leadersObservable.leaderboardUiModel.showProgress {
                                
                                Section(header:  HStack {
                                    Text(StringConstants.name)
                                    Spacer()
                                    Text(StringConstants.score)
                                }) {
                                    ForEach(self.leadersObservable.leaderboardUiModel.scores) { model in
                                        HStack {
                                            Text(model.userName)
                                            Spacer()
                                            Text(String(model.userScore))
                                        }.listRowBackground(model.backgroundColor).id(model.id)
                                    }
                                }
                                
                            }
                            
                        }
                        .onChange(of: leadersObservable.leaderboardUiModel.userScoreIndex, perform: { _ in
                            proxy.scrollTo(Int64(self.leadersObservable.leaderboardUiModel.userScoreIndex))
                        })
                        .overlay(
                            Group {
                                if (self.leadersObservable.leaderboardUiModel.scores.isEmpty) {
                                    ZStack() {
                                        Color(.systemBackground).ignoresSafeArea()
                                    }
                                }
                            })
                        .refreshable {
                            self.leadersObservable.updateScores(self.chartObservable.currentPriceCents())
                            await Task.sleep(1_000_000_000)
                        }
                        
                    }
                }
            }
            
            
            if self.leadersObservable.leaderboardUiModel.showProgress {
                ProgressView()
            }
        }
        .snackbar(errorState: $leadersObservable.errorState)
        
        .overlay(self.leadersObservable.leaderboardUiModel.showSignupPrompt ? joinPrompt : nil, alignment: .bottom)
        .onAppear(perform: {
            if (self.leadersObservable.leaderboardUiModel.scores.isEmpty) {
                self.leadersObservable.updateScores(self.chartObservable.currentPriceCents())
            }
        })
    }
    
    private var joinPrompt: some View {
        VStack() {
            Text(StringConstants.joinLead)
            
            TextField(StringConstants.nickPrompt, text: $username)
                .onReceive(Just($username)) { _ in limitText(&username, usernameMaxChars) }
                .disableAutocorrection(true)
                .padding()
                .background(Color(.systemBackground))
            
            Button(action: {
                self.leadersObservable.onUserJoin(username, self.chartObservable.currentPriceCents())
            }) {
                Text(StringConstants.joinBtnTitle)
            }.padding([.horizontal], 20).padding([.vertical], 10).foregroundColor(.white).background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 18)).buttonStyle(PlainButtonStyle())
                .disabled(self.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
        }
        .padding([.horizontal], 20)
        .padding([.vertical], 30)
        .background(Color(.secondarySystemBackground))
        .overlay(Rectangle()
            .frame(width: nil, height: 1, alignment: .top)
            .foregroundColor(Color(.separator)), alignment: .top)
        
    }
    
    func limitText(_ text: inout String, _ limit: Int) {
        if (text.count > limit) {
            text = String(text.prefix(limit))
        }
    }
}
