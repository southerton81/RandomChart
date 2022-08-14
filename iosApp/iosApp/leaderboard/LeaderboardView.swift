import Foundation
import SwiftUI
import Combine

struct LeaderboardView: View {
    @StateObject var leadersObservableObject = LeadersObservableObject()
    @State private var username: String = ""
    let usernameMaxChars = 30
    let container: PersistentContainer
    
    init(_ c: PersistentContainer) {
        self.container = c 
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            
            VStack(spacing: 0) {
                Spacer()
                Text("Leaderboard")
                Spacer()
                
                ScrollViewReader { proxy in
                    
                    VStack {
                        List(self.leadersObservableObject.leaderboardUiModel.scores) { model in
                            HStack {
                                Text(model.userName)
                                Spacer()
                                Text(String(model.userScore))
                            }.listRowBackground(model.backgroundColor).id(model.id)
                            
                        }.listStyle(SidebarListStyle())
                            .onChange(of: leadersObservableObject.leaderboardUiModel.userScoreIndex, perform: { _ in
                                proxy.scrollTo(Int64(self.leadersObservableObject.leaderboardUiModel.userScoreIndex))
                            })
                    }
                }
                
                if self.leadersObservableObject.leaderboardUiModel.showSignupPrompt {
                    joinPrompt
                }
            }
            
            if self.leadersObservableObject.leaderboardUiModel.showProgress {
                ProgressView()
            }
        }
        .snackbar(errorState: $leadersObservableObject.errorState)
        .onAppear(perform: {
            self.leadersObservableObject.updateScores(self.container)
        })
    }
    
    private var joinPrompt: some View {
        VStack() {
            Text("Join Leaderboard")
            
            TextField("Nickname", text: $username)
                .onReceive(Just($username)) { _ in limitText(&username, usernameMaxChars) }
                .disableAutocorrection(true)
                .padding()
                .background(Color(.systemBackground))
            
            Button(action: {
                self.leadersObservableObject.onUserJoin(container, username)
            }) {
                Text("Join")
            }.padding([.horizontal], 20).padding([.vertical], 10).foregroundColor(.white).background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 18)).buttonStyle(PlainButtonStyle())
                .disabled(self.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
        }.padding([.horizontal], 20).padding([.vertical], 30).background(Color(.secondarySystemBackground))
            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color(.separator)), alignment: .top)
    }
    
    func limitText(_ text: inout String, _ limit: Int) {
        if (text.count > limit) {
            text = String(text.prefix(limit))
        }
    }
}
