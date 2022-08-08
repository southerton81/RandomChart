import Foundation
import SwiftUI
import Combine

struct LeaderboardView: View {
    @ObservedObject var leadersObservableObject = LeadersObservableObject()
    @State private var username: String = ""
    let usernameMaxChars = 30
    
    var body: some View {
        ZStack(alignment: .center) {
            
            VStack(spacing: 0) {
                Spacer()
                Text("Leaderboard")
                Spacer()
                
                List(self.leadersObservableObject.leaderboardUiModel.scores) { model in
                    let backgroundColor = model.id % 2 == 0 ? Color(UIColor.secondarySystemBackground) : Color(UIColor.tertiarySystemBackground)
                    
                    HStack {
                        Text(model.userName)
                        Spacer()
                        Text(String(model.userScore))
                    }.listRowBackground(backgroundColor)
                    
                }.listStyle(SidebarListStyle())
                
                if self.leadersObservableObject.leaderboardUiModel.showSignupPrompt {
                    VStack() {
                        Text("Join Leaderboard")
                        
                        TextField("Nickname", text: $username)
                            .onReceive(Just($username)) { _ in limitText(&username, usernameMaxChars) }
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color(.systemBackground))
                        
                        Button(action: {
                            self.leadersObservableObject.onUserJoin(username)
                        }) {
                            Text("Join")
                        }.padding([.horizontal], 20).padding([.vertical], 10).foregroundColor(.white).background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 18)).buttonStyle(PlainButtonStyle())
                            .disabled(self.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                          
                    }.padding([.horizontal], 20).padding([.vertical], 30).background(Color(.secondarySystemBackground))
                        .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color(.separator)), alignment: .top)
                }
            }
            
            if self.leadersObservableObject.leaderboardUiModel.showProgress {
                ProgressView()
            }
        }
        .snackbar(errorState: $leadersObservableObject.errorState)
        .onAppear(perform: {
            self.leadersObservableObject.fetch()
        })
    }
    
    func limitText(_ text: inout String, _ limit: Int) {
        if (text.count > limit) {
            text = String(text.prefix(limit))
        }
    }
}
