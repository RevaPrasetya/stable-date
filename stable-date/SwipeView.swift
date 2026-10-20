import SwiftUI
import UIKit

struct Horse: Identifiable, Decodable, Equatable {
    var id: String
    var name: String
    var age: Int
    var breed: String
    var bio: String
    var lookingFor: String
    var imageName: String
    var likesYouBack: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case breed
        case bio
        case lookingFor
        case imageName
        case likesYouBack
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? "Horse"
        age = (try? c.decode(Int.self, forKey: .age)) ?? 0
        breed = (try? c.decode(String.self, forKey: .breed)) ?? ""
        bio = (try? c.decode(String.self, forKey: .bio)) ?? ""
        lookingFor = (try? c.decode(String.self, forKey: .lookingFor)) ?? ""
        imageName = (try? c.decode(String.self, forKey: .imageName)) ?? ""
        likesYouBack = (try? c.decode(Bool.self, forKey: .likesYouBack)) ?? false
    }
}

struct SwipeView: View {
    @State var horses: [Horse] = []
    @State var isLoading = true
    @State var matches: [Horse] = []
    @State var showMatch = false
    @State var matchedName = ""
    @State var selectedHorse: Horse?
    @State var dragOffset: CGSize = .zero
    @State var cardRotation: Double = 0
    @State var isAnimating = false
    @State var confettiVisible = false
    @State var confettiSeed = 0

    static var horsesURL: URL {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["STABLE_DATE_URL"],
           let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://raw.githubusercontent.com/revaprasetya/stable-date/main/Data/horses.json")!
    }

    var body: some View {
        VStack(spacing: 0) {
            // header
            HStack {
                Button {} label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.rose)
                        .frame(width: 56, height: 56)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.blush, lineWidth: 1) }
                }
                .accessibilityLabel("Back")
                Spacer()
                VStack(spacing: 2) {
                    Text("Discover").font(.title.bold()).foregroundStyle(Color.ink)
                    Text("Ubud, Bali").font(.headline.weight(.regular)).foregroundStyle(Color.inkSecondary)
                }
                Spacer()
                Button {} label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.rose)
                        .frame(width: 56, height: 56)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.blush, lineWidth: 1) }
                }
                .accessibilityLabel("Filters")
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ZStack {
                if isLoading {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.blush.opacity(0.7))
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay {
                            VStack(spacing: 20) {
                                ProgressView().controlSize(.large).tint(Color.rose)
                                Text("Rounding up horses...").font(.title3.weight(.semibold)).foregroundStyle(Color.ink)
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(maxHeight: .infinity, alignment: .top)
                } else if !horses.isEmpty {
                    ZStack {
                        // the cards behind
                        if horses.count > 2 {
                            Color.photoPink
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay { Image(horses[2].imageName).resizable().scaledToFill() }
                                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                .scaleEffect(0.92, anchor: .bottom)
                                .offset(y: 16)
                        }
                        if horses.count > 1 {
                            Color.photoPink
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay { Image(horses[1].imageName).resizable().scaledToFill() }
                                .overlay(alignment: .bottomLeading) {
                                    LinearGradient(colors: [.clear, Color.ink.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                        .frame(height: 160)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                .shadow(color: Color.rose.opacity(0.18), radius: 20, y: 10)
                                .scaleEffect(0.96, anchor: .bottom)
                                .offset(y: 8)
                        }
                        // the top card
                        Color.photoPink
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay {
                                if UIImage(named: horses[0].imageName) != nil {
                                    Image(horses[0].imageName).resizable().scaledToFill()
                                } else {
                                    Image(systemName: "hare").font(.system(size: 96)).foregroundStyle(Color.ink.opacity(0.4))
                                }
                            }
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(horses[0].name), \(horses[0].age)")
                                        .font(.title.bold())
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.7)
                                    Text("\(horses[0].breed) · \(horses[0].bio)")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .opacity(0.85)
                                }
                                .foregroundStyle(.white)
                                .padding(.leading, 24)
                                .padding(.trailing, 72)
                                .padding(.top, 72)
                                .padding(.bottom, 24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background { LinearGradient(colors: [.clear, Color.ink.opacity(0.7)], startPoint: .top, endPoint: .bottom) }
                            }
                            .overlay(alignment: .top) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin")
                                        Text("\(horses[0].age % 4 + 1) km")
                                    }
                                    .foregroundStyle(Color.ink)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Image(systemName: "heart.fill")
                                        Text("\(70 + (horses[0].age * 7) % 29)%")
                                    }
                                    .foregroundStyle(Color.lavender)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule())
                                }
                                .font(.subheadline.bold())
                                .padding(16)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .shadow(color: Color.rose.opacity(0.18), radius: 20, y: 10)
                            .environment(\.colorScheme, .light)
                            .offset(dragOffset)
                            .rotationEffect(.degrees(cardRotation))
                            .onTapGesture { selectedHorse = horses[0] }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if isAnimating { return }
                                        dragOffset = value.translation
                                        cardRotation = Double(value.translation.width / 50)
                                    }
                                    .onEnded { value in
                                        if isAnimating { return }
                                        if value.translation.width > 120 {
                                            handle(true)
                                        } else if value.translation.width < -120 {
                                            handle(false)
                                        } else {
                                            withAnimation(.spring(duration: 0.3)) {
                                                dragOffset = .zero
                                                cardRotation = 0
                                            }
                                        }
                                    }
                            )
                    }
                    .overlay(alignment: .bottomTrailing) {
                        VStack(spacing: 12) {
                            Button { handle(false) } label: {
                                Image(systemName: "xmark").font(.title2.weight(.bold)).foregroundStyle(Color.plum)
                                    .frame(width: 62, height: 62)
                                    .background { Circle().fill(.white).shadow(color: Color.rose.opacity(0.2), radius: 10, y: 4) }
                            }
                            .accessibilityLabel("Nope")
                            Button { handle(true) } label: {
                                Image(systemName: "star.fill").font(.title2.weight(.bold)).foregroundStyle(Color.lavender)
                                    .frame(width: 62, height: 62)
                                    .background { Circle().fill(Color.lavenderSoft).shadow(color: Color.rose.opacity(0.2), radius: 10, y: 4) }
                            }
                            .accessibilityLabel("Super like")
                            Button { handle(true) } label: {
                                Image(systemName: "heart.fill").font(.title2.weight(.bold)).foregroundStyle(.white)
                                    .frame(width: 62, height: 62)
                                    .background { Circle().fill(Color.rose).shadow(color: Color.rose.opacity(0.2), radius: 10, y: 4) }
                            }
                            .accessibilityLabel("Like")
                        }
                        .offset(x: 12, y: -24)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // tab bar
            HStack {
                Image(systemName: "rectangle.stack.fill").font(.title2).foregroundStyle(Color.rose).frame(maxWidth: .infinity, minHeight: 44)
                Image(systemName: "heart").font(.title2).foregroundStyle(Color.inkSecondary.opacity(0.6)).frame(maxWidth: .infinity, minHeight: 44)
                    .overlay(alignment: .topTrailing) {
                        if matches.count > 0 {
                            Text("\(matches.count)").font(.caption2.bold()).foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.rose, in: Capsule())
                                .offset(x: -18, y: 4)
                        }
                    }
                    .accessibilityLabel("\(matches.count) matches")
                Image(systemName: "bubble.left").font(.title2).foregroundStyle(Color.inkSecondary.opacity(0.6)).frame(maxWidth: .infinity, minHeight: 44)
                Image(systemName: "person").font(.title2).foregroundStyle(Color.inkSecondary.opacity(0.6)).frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.top, 12)
            .padding(.bottom, 4)
            .background { Rectangle().fill(.background).ignoresSafeArea(edges: .bottom) }
        }
        .background { Color.appBackground.ignoresSafeArea() }
        .task {
            guard let (data, _) = try? await URLSession.shared.data(from: Self.horsesURL),
                  let decoded = try? JSONDecoder().decode([Horse].self, from: data)
            else { return }
            horses = decoded; isLoading = false
        }
        .sheet(item: $selectedHorse) { horse in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Color.photoPink
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay { Image(horse.imageName).resizable().scaledToFill() }
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    Text(horse.name).font(.largeTitle.bold()).foregroundStyle(Color.ink)
                    Text("\(horse.age) years · \(horse.breed)").font(.title3.weight(.semibold)).foregroundStyle(Color.inkSecondary)
                    Text(horse.bio).font(.body).foregroundStyle(Color.ink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Looking for").font(.headline).foregroundStyle(Color.rose)
                        Text(horse.lookingFor).font(.body).foregroundStyle(Color.ink)
                    }
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .presentationDragIndicator(.visible)
        }
        .overlay {
            if showMatch {
                ZStack {
                    LinearGradient(colors: [.appBackground, .blush], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    if confettiVisible {
                        confetti
                    }
                    VStack(spacing: 12) {
                        Spacer(minLength: 0)
                        ZStack {
                            Image("horse-04").resizable().scaledToFill()
                                .frame(width: 160, height: 210)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white, lineWidth: 6) }
                                .rotationEffect(.degrees(-9))
                                .offset(x: -70, y: -24)
                            Image(matches.last?.imageName ?? "horse-01").resizable().scaledToFill()
                                .frame(width: 160, height: 210)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white, lineWidth: 6) }
                                .rotationEffect(.degrees(7))
                                .offset(x: 70, y: 24)
                        }
                        .padding(.bottom, 36)
                        Text("CONGRATULATIONS").font(.subheadline.bold()).tracking(4).foregroundStyle(Color.rose)
                        Text("It's a match!!").font(.largeTitle.bold()).foregroundStyle(Color.ink)
                        Text("You and \(Text(matchedName).bold().foregroundStyle(Color.ink)) are now trotting together.")
                            .font(.title3).foregroundStyle(Color.inkSecondary)
                        Spacer(minLength: 0)
                        Button { update() } label: {
                            Text("Say hello").font(.title3.bold()).foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color.rose, in: Capsule())
                        }
                        Button { update() } label: {
                            Text("Keep trotting").font(.title3.bold()).foregroundStyle(Color.rose)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(.white, in: Capsule())
                                .overlay { Capsule().strokeBorder(Color.blush, lineWidth: 2) }
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                }
                .environment(\.colorScheme, .light)
                .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.4), value: showMatch)
    }

    // don't touch this, it works
    var confetti: some View {
        Canvas { context, size in
            var seed = UInt64(confettiSeed + 1)
            func next() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 33) / Double(UInt32.max >> 1)
            }
            let colors: [Color] = [.rose, .lavender, .blush, .plum, .photoMint, .photoPeach]
            for i in 0..<80 {
                let x = next() * size.width
                let y = next() * size.height * 0.7
                let w = 6 + next() * 8
                let h = 4 + next() * 10
                let angle = Angle.degrees(next() * 360)
                var piece = context
                piece.translateBy(x: x, y: y)
                piece.rotate(by: angle)
                let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                let color = colors[i % colors.count]
                if i % 3 == 0 {
                    piece.fill(Path(ellipseIn: rect), with: .color(color))
                } else {
                    piece.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    func handle(_ right: Bool) {
        if isAnimating || horses.isEmpty { return }
        isAnimating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let horse = horses[0]
        withAnimation(.easeOut(duration: 0.35)) {
            dragOffset = CGSize(width: right ? 600 : -600, height: -40)
            cardRotation = right ? 12 : -12
        } completion: {
            if right {
                like(horse)
            } else {
                nope(horse)
            }
            refresh()
        }
    }

    func like(_ horse: Horse) {
        horses.removeAll { $0.id == horse.id }
        if horse.likesYouBack { matches.append(horse); matchedName = horse.name; showMatch = true }
    }

    func nope(_ horse: Horse) {
        horses.removeAll { $0.id == horse.id }
        if horse.likesYouBack { matches.append(horse); matchedName = horse.name; showMatch = true }
    }

    func refresh() {
        dragOffset = .zero
        cardRotation = 0
        isAnimating = false
        // TODO: fix later
        if showMatch {
            confettiSeed += 1
            confettiVisible = true
        }
    }

    func update() {
        showMatch = false
        confettiVisible = false
        matchedName = ""
    }
}

#Preview {
    SwipeView()
}
