class IK_FABRIKChain {
    // FABRIK: Forwards and Backwards Reaching Inverse Kinematics
    // This class represents a chain of segments that can be used to solve IK problems
    // The chain is created with a specified number of segments and a distance constant
    // Once the chain is created, you can call Solve to solve the IK problem
    // Once solved, you can set the positions of the Actors which represent the chain segments to the positions of the chain segments from this class

    // Here's a usage example:
    // We will create a zombieman with a chain of 6 segments which moves around in a wavy pattern around the zombieman

    /*
    class Zombieman_IKDemo : Zombieman replaces Zombieman
    {
        IK_FABRIKChain chain;                  // The mathematical representation of the chain
        Array<Zombieman_Chainlink> chainVis;    // The visual representation of the chain; defined below

        override void PostBeginPlay() {
            Super.PostBeginPlay();

            int ik_distanceConstant = 20;       // The distance between each segment in the chain
            int ik_numSegments = 6;             // The number of segments in the chain

            // Create the chain
            chain = chain.Create(ik_numSegments, ik_distanceConstant, Pos + (0, 0, Height / 2), Pos + (0, ik_distanceConstant * (ik_numSegments - 1)));
            
            // Create the chain visualizer
            for (int i = 0; i < ik_numSegments; i++) {
                let [spawned, actor] = A_SpawnItemEx("Zombieman_Chainlink", flags: SXF_SETMASTER);
                Zombieman_Chainlink vis = Zombieman_Chainlink(actor);
                chainVis.Push(vis);
            }
        }

        override void Tick() {
            Super.Tick();

            // The start position of our demo chain follows this actor
            Vector3 startPos = Pos + (0, 0, Height / 2);

            // Move the end segment of the chain around this actor, to demonstrate the chain's movement
            Vector3 endPos = Pos + ((100 * sin(Level.Time)) * cos(Level.Time * 15), (100 * sin(Level.Time)) * sin(Level.Time * 15), -sin(Level.Time) * 30 + 30);

            // Solve IK for the positions of each link in the chain based on the new start and end positions
            chain.Solve(startPos, endPos);

            // Update the position of the chain Actors based on the new positions of the chain segments
            for (int i = 0; i < chain.Size(); i++) {
                chainVis[i].SetOrigin(chain.segments[i].Pos, true);
                
                // Optional: Make sure we don't clip into the floor
                if (chainVis[i].Z < chainVis[i].floorz) chainVis[i].SetOrigin(chainVis[i].Pos.PlusZ(-(chainVis[i].Pos.Z - chainVis[i].floorz)), true);
            }
        }
    }

    class Zombieman_Chainlink : Actor
    {
        // Optional: Disable interaction for the chain links
        Default {
            +NOINTERACTION;
            +NOBLOCKMAP;
        }

        States {
            Spawn:
                APBX A 1;   // Using a ball-shaped, center-aligned sprite from doom2.wad as a placeholder visual
                Loop;
        }
    }

    */

    array<IK_FABRIKSegment> segments;
    float distanceConstant;

    static IK_FABRIKChain Create(int numSegments, int distanceConstant, vector3 startPos = (0, 0, 0), vector3 endPos = (0, 0, 0)) {
        // Create a chain with the specified number of segments
        IK_FABRIKChain chain = new("IK_FABRIKChain");
        for (int i = 0; i < numSegments; i++) {
            IK_FABRIKSegment segment = new("IK_FABRIKSegment");
            segment.Pos = (0., 0., 0.);
            chain.segments.Push(segment);
        }

        // Set the start and end positions
        chain.segments[0].Pos = startPos;
        chain.segments[numSegments - 1].Pos = endPos;

        // Set the distance constant
        chain.distanceConstant = distanceConstant;

        // Project chain to start
        chain.ProjectChainTowardsEndpoint(startPos, endPos);

        return chain;
    }

    int numSegments() {
        return segments.Size();
    }

    IK_FABRIKSegment firstSegment() {
        return segments[0];
    }

    IK_FABRIKSegment lastSegment() {
        return segments[segments.Size() - 1];
    }

    void ProjectChainTowardsEndpoint(Vector3 startPoint, Vector3 endPoint) {
        // Project the chain towards the end point
        Vector3 startToEnd = endPoint - startPoint;
        float totalChainLength = numSegments() * distanceConstant;

        // Get unit vector and just travel in that direction for the total chain length
        Vector3 direction = startToEnd.Unit();
        Vector3 endPos = startPoint + direction * totalChainLength;

        for (int i = 0; i < numSegments(); i++) {
            segments[i].Pos = startPoint + direction * (i + 1) * distanceConstant;
        }
    }

    void Solve(Vector3 targetStartPosition, Vector3 targetEndPosition) {
        // console.Printf("IK Solver: Target start position "..targetStartPosition);
        // console.Printf("IK Solver: Target end position "..targetEndPosition);
        
        Vector3 startToEnd = targetEndPosition - targetStartPosition;
        float startToEndLength = startToEnd.Length();
        float totalChainLength = numSegments() * distanceConstant;

        if (startToEndLength > totalChainLength) {
            // The target is out of reach
            // Console.Printf("IK Solver: Target is out of reach");

            // Project the chain towards the end point
            ProjectChainTowardsEndpoint(targetStartPosition, targetEndPosition);

            return;
        }

        // Otherwise, we need to do IK
        // Console.Printf("IK Solver: Target is reachable");

        // Start with one pass to make sure we're up to date with movement
        BackwardPass(targetEndPosition);
        ForwardPass(targetStartPosition);
        
        // Print a full representation of the chain
        // console.printf("Chain: %d segments", numSegments());
        // for (int i = 0; i < numSegments(); i++) {
        //     Console.Printf("IK Solver: Segment %d position %f, %f, %f", i, segments[i].Pos.X, segments[i].Pos.Y, segments[i].Pos.Z);
        // }
    
        // Iterate until we're close enough
        double distanceThreshold = 0.2; // Set this to your preferred margin of error; the lower the number, the more accurate the IK solver will be but the more iterations it will take
        while((lastSegment().Pos - targetEndPosition).Length() > distanceThreshold && (firstSegment().Pos - targetStartPosition).Length() > distanceThreshold) {
            BackwardPass(targetEndPosition);
            ForwardPass(targetStartPosition);
        }
    }

    void BackwardPass(Vector3 targetEndPosition) {
        // FABRIK solve backwards
        // Create an array to hold our prime positions
        array<IK_FABRIKSegment> segmentsPrime;

        for (int i = 0; i < numSegments(); i++) {
            segmentsPrime.Push(new("IK_FABRIKSegment"));
            segmentsPrime[i].Pos = (0.,0.,0.);
        }

        // Put the last segmentPrime at the end position
        segmentsPrime[numSegments() - 1].Pos = targetEndPosition;

        // Solve backwards
        for (int i = numSegments() - 1; i >= 1; i--) {
            // Subtract the current segment's position from the previous segment's position
            Vector3 direction = segments[i - 1].Pos - segmentsPrime[i].Pos;
            direction = direction.Unit();

            // Multiply the direction by the distance constant to get the new position for the previous segment
            Vector3 scaledDirection = direction * distanceConstant;

            // Multiply by the distance constant to get the new position for the previous segment
            segmentsPrime[i - 1].Pos = segmentsPrime[i].Pos + scaledDirection;
        }

        // Copy the prime positions back to the segments
        segments = segmentsPrime;
    }

    void ForwardPass(Vector3 targetStartPosition) {
        // FABRIK solve forwards
        // Create an array to hold our prime positions
        array<IK_FABRIKSegment> segmentsPrime;

        for (int i = 0; i < numSegments(); i++) {
            segmentsPrime.Push(new("IK_FABRIKSegment"));
            segmentsPrime[i].Pos = (0.,0.,0.);
        }

        // Put the first segment prime at the start position
        segmentsPrime[0].Pos = targetStartPosition;

        // Solve forwards
        for (int i = 0; i < numSegments() - 1; i++) {
            // Subtract the current segment's position from the next segment's position
            Vector3 direction = segments[i + 1].Pos - segmentsPrime[i].Pos;
            direction = direction.Unit();

            // Multiply the direction by the distance constant to get the new position for the next segment
            Vector3 scaledDirection = direction * distanceConstant;

            // Multiply by the distance constant to get the new position for the next segment
            segmentsPrime[i + 1].Pos = segmentsPrime[i].Pos + scaledDirection;
        }

        segments = segmentsPrime;
    }
}

class IK_FABRIKSegment {
    // Object to hold position information for a segment in the chain
    // I was having trouble instantiating arrays of Vec3s so I made this class
    Vector3 Pos;
}