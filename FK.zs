class FK_Segment : Actor {
    // Forward kinematics segment
    // Inherit from this for the segments of snakes and necks and worms and tails and stuff
    // Each segment will follow the previous one in a chain as a linked list

    // To use this, put the following in your "leader" actor (the "head" of the "snake"):
    /*
        Array<FK_Segment> tailLinks;

        override void PostBeginPlay()
        {
            Super.PostBeginPlay();

            // Create the tail and set the next fields
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
            Vector3 firstLinkPos = FK_Library.FollowSegmentAtDistance(self, tailLinks[0], 128, Height / 2);
            tailLinks[0].SetOrigin(firstLinkPos, true);
        }
    */

    Default {
        +NOINTERACTION;
        +NOGRAVITY;
        +NOBLOCKMAP;

        Height 10;
    }

    FK_Segment next;     // Container for the next link in the chain
    int distanceConstant;

    override void PostBeginPlay() {
        Super.PostBeginPlay();
        // distanceConstant = 32;
    }

    override void Tick() {
        Super.Tick();

        Vector3 currentSegmentNextPos;

        if (!next) {
            // Follow the spawner
            // SetOrigin(master.Pos, true);
            return;
        } else {
            // Find the position for the next link in the chain
            currentSegmentNextPos = FK_Library.FollowSegmentAtDistance(self, next, distanceConstant, Height / 2);

            // Move the next link in the chain to the end of the vector
            next.SetOrigin(currentSegmentNextPos, true);
        }
    }

    void SetNext(FK_Segment nextLink) {
        next = nextLink;
    }

    States {
        Spawn:
            APBX A 1;   // Using a ball-shaped, center-aligned sprite from doom2.wad as a placeholder visual
            Loop;
    }
}

class FK_Library {
    static Vector3 FollowSegmentAtDistance(Actor toFollow, Actor currentSegment, int distanceConstant, double currentSegmentPitchCalcZOffset = 0) {
        // Forward kinematics
        // Draw a vector from our current position to the next link in the chain
        let angleToTarget = currentSegment.AngleTo(toFollow);
        let pitchToTarget = currentSegment.PitchTo(toFollow, currentSegmentPitchCalcZOffset, toFollow.Height / 2);  // Divide by two to start from the center of this actor

        // Scale the vector to the distance constant
        Vector3 distanceVector = (toFollow.Pos) - currentSegment.Pos;
        let distanceToTarget = distanceVector.Length();

        // Project the distance vector onto a unit sphere and scale it to the distance constant, then add it to the current segment's position
        let currentSegmentNextPos = toFollow.Pos + (
            distanceConstant * cos(angleToTarget - 180) * cos(pitchToTarget), 
            distanceConstant * sin(angleToTarget - 180) * cos(pitchToTarget), 
            distanceConstant * sin(pitchToTarget)
        );

        // Make sure we don't clip into the ground
        if (currentSegmentNextPos.Z < currentSegment.floorZ) currentSegmentNextPos.Z = currentSegment.floorZ;

        // Console.printf("Next segment pos: %f, %f, %f", currentSegmentNextPos.X, currentSegmentNextPos.Y, currentSegmentNextPos.Z);

        return currentSegmentNextPos;
    }
}