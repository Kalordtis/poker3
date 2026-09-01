import SwiftUI

import Combine // Add this line to fix the errors

// MARK: - Models



// MARK: - Models
enum Suit: String, CaseIterable {
    case hearts = "♥️", diamonds = "♦️", clubs = "♣️", spades = "♠️"
    var color: Color { self == .hearts || self == .diamonds ? .red : .black }
}

enum Rank: Int, CaseIterable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace
    
    var stringValue: String {
        switch self {
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        default: return "\(self.rawValue)"
        }
    }
}

struct Card: Identifiable, Equatable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
}

enum GamePhase {
    case preFlop, flop, turn, river, showdown
}

// MARK: - Game Engine & Coach
class PokerEngine: ObservableObject {
    @Published var playerHand: [Card] = []
    @Published var communityCards: [Card] = []
    @Published var deck: [Card] = []
    @Published var currentPhase: GamePhase = .preFlop
    @Published var potSize: Int = 0
    @Published var coachMessage: String = "Welcome to the table. Let's learn to play mathematically winning poker."
    @Published var coachTitle: String = "PokerBank Coach"
    
    init() {
        startNewHand()
    }
    
    func startNewHand() {
        // Create and shuffle deck
        deck = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        deck.shuffle()
        
        playerHand = [deck.removeLast(), deck.removeLast()]
        communityCards = []
        currentPhase = .preFlop
        potSize = Int.random(in: 10...50)
        analyzeSituation()
    }
    
    func advancePhase() {
        switch currentPhase {
        case .preFlop:
            communityCards.append(contentsOf: [deck.removeLast(), deck.removeLast(), deck.removeLast()])
            currentPhase = .flop
            potSize += Int.random(in: 20...80)
        case .flop:
            communityCards.append(deck.removeLast())
            currentPhase = .turn
            potSize += Int.random(in: 40...100)
        case .turn:
            communityCards.append(deck.removeLast())
            currentPhase = .river
            potSize += Int.random(in: 50...150)
        case .river:
            currentPhase = .showdown
        case .showdown:
            startNewHand()
            return
        }
        analyzeSituation()
    }
    
    // This is where your strategy text is applied contextually
    func analyzeSituation() {
        switch currentPhase {
        case .preFlop:
            let isPocketPair = playerHand[0].rank == playerHand[1].rank
            if isPocketPair {
                coachTitle = "Combinatorics: Pocket Pairs"
                coachMessage = "You were dealt a pocket pair! There are only 6 combinations of any specific pair (like \(playerHand[0].rank.stringValue)\(playerHand[0].rank.stringValue)) in a 52-card deck. It's rare—play it smart."
            } else {
                coachTitle = "Combinatorics: Unpaired Hands"
                coachMessage = "You have an unpaired hand. There are 16 ways to be dealt these specific two cards. Remember: you are 3 times more likely to be dealt an unpaired hand than a pocket pair!"
            }
            
        case .flop:
            // Simulating a flush draw check
            let suitCounts = (playerHand + communityCards).reduce(into: [Suit: Int]()) { $0[$1.suit, default: 0] += 1 }
            let hasFlushDraw = suitCounts.values.contains(4)
            
            if hasFlushDraw {
                coachTitle = "Pot Odds & The Rule of 4 and 2"
                coachMessage = "You have a Flush Draw! You have 9 'outs' (remaining cards of that suit). Multiply your outs by 4 on the flop: 9 x 4 = 36%. You have a ~36% Equity to hit your flush. Only call a bet if the Pot Odds are cheaper than 36%!"
            } else {
                coachTitle = "Expected Value (EV)"
                coachMessage = "Every decision revolves around EV. If you bet here and your opponent folds often enough, it's a +EV play (profitable long-term). If you have nothing, calling is a -EV play."
            }
            
        case .turn:
            coachTitle = "Implied Odds"
            coachMessage = "There is $\(potSize) in the pot. Implied odds look at future bets. If you hit your winning card on the river, will your opponent pay you off? If yes, you can sometimes call a bet even if your direct Pot Odds are slightly bad."
            
        case .river:
            coachTitle = "Pot Equity"
            coachMessage = "The board is complete. You either have the best hand or you don't. If you think you have >50% Equity here, bet for value! Get as much money into the $\(potSize) pot as possible."
            
        case .showdown:
            coachTitle = "Sklansky Dollars"
            coachMessage = "Whether you won or lost this hand in real money, what matters is your Equity when the money went in. If you made the right mathematical call, you earned 'Sklansky Dollars'. The math always wins in the long run!"
        }
    }
}

// MARK: - Views
struct ContentView: View {
    @StateObject private var engine = PokerEngine()
    
    var body: some View {
        ZStack {
            // Poker Table Green Background
            Color(red: 0.1, green: 0.4, blue: 0.2)
                .ignoresSafeArea()
            
            VStack {
                // Top: Pot Info
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title)
                    Text("Pot: $\(engine.potSize)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Middle: Community Cards
                Text("Board")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.headline)
                
                HStack(spacing: 10) {
                    if engine.communityCards.isEmpty {
                        ForEach(0..<3) { _ in CardPlaceholder() }
                    } else {
                        ForEach(engine.communityCards) { card in
                            CardView(card: card)
                        }
                    }
                }
                .padding(.bottom, 40)
                
                // Bottom: Player Cards
                Text("Your Hand")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.headline)
                
                HStack(spacing: 15) {
                    ForEach(engine.playerHand) { card in
                        CardView(card: card)
                    }
                }
                
                Spacer()
                
                // Coach Panel
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(.blue)
                        Text(engine.coachTitle)
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    
                    Text(engine.coachMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding(.horizontal)
                
                // Action Button
                Button(action: {
                    withAnimation {
                        engine.advancePhase()
                    }
                }) {
                    Text(engine.currentPhase == .showdown ? "Deal Next Hand" : "Advance Phase")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

struct CardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 3)
            
            VStack {
                Text(card.rank.stringValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(card.suit.color)
                Text(card.suit.rawValue)
                    .font(.title)
            }
        }
        .frame(width: 65, height: 90)
    }
}

struct CardPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .background(Color.black.opacity(0.2))
            .frame(width: 65, height: 90)
    }
}
