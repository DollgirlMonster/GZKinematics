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
        for (int i = 0; i < chainVis.Size(); i++) {
            chainVis[i].SetOrigin(chain.segments[i].Pos, true);
            
            // Optional: Make sure we don't clip into the floor
            if (chainVis[i].Pos.Z < chainVis[i].floorz) chainVis[i].SetOrigin(chainVis[i].Pos.PlusZ(-(chainVis[i].Pos.Z - chainVis[i].floorz)), true);
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