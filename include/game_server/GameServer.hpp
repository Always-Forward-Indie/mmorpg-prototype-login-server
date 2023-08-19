//declare class GameServer 
class GameServer {
    // Public methods
    public:
        // Constructor
        GameServer();
        // Destructor
        ~GameServer();
        // Initialize the game server
        void initialize();
        // Shutdown the game server
        void shutdown();
    // Private methods
    private:
        // Initialize the game server's network
        void initializeNetwork();
        // Shutdown the game server's network
        void shutdownNetwork();

};