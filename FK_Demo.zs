class Cacodemon_FKDemo : Cacodemon replaces Cacodemon
{
    // This chain chomp-style cacodemon has a tail!
    Array<FK_Segment> tailLinks;    // The segments of the tail

    override void PostBeginPlay()
    {
        Super.PostBeginPlay();
    
        // Create the tail and set the 'next' fields therein
        FK_Segment previousTail;
        for (int i = 0; i < 5; i++) {
            // Create the tail segment actor
            let [spawned, actor] = A_SpawnItemEx("FK_Segment", flags: SXF_SETMASTER);
            let tail = FK_Segment(actor);
    
            // Set the distance between each segment and add it to the list
            tail.distanceConstant = 32; // Distance between each segment
            tailLinks.Push(tail);
    
            // Set the 'next' field of the previous segment (if one exists) to this segment
            if (previousTail) previousTail.next = tail;
            previousTail = tail;
        }
    }
    
    override void Tick() {
        Super.Tick();
    
        // Drag the first link of the tail around
        Vector3 firstLinkPos = FK_Library.FollowSegmentAtDistance(self, tailLinks[0], 32, Height / 2);
        tailLinks[0].SetOrigin(firstLinkPos, true);
    }
}