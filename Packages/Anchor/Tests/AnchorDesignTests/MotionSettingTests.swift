import Testing
@testable import AnchorDesign

@Test func mostRestrictiveMotionWins() {
    #expect(AnchorMotion.effective(user: .full, systemReduceMotion: true) == .reduced)
    #expect(AnchorMotion.effective(user: .off, systemReduceMotion: false) == .off)
    #expect(AnchorMotion.effective(user: .off, systemReduceMotion: true) == .off)
    #expect(AnchorMotion.effective(user: .reduced, systemReduceMotion: false) == .reduced)
    #expect(AnchorMotion.effective(user: .full, systemReduceMotion: false) == .full)
}

@Test func animationIsNilWhenMotionOff() {
    #expect(AnchorMotion.animation(for: .off) == nil)
    #expect(AnchorMotion.animation(for: .full) != nil)
    #expect(AnchorMotion.animation(for: .reduced) != nil)
}
