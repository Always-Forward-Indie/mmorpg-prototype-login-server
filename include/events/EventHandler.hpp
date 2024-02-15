#include "Event.hpp"
#include <string>
#include <boost/asio.hpp>
#include "data/ClientData.hpp"
#include "network/NetworkManager.hpp"
#include "utils/ResponseBuilder.hpp"
#include "utils/Logger.hpp"
#include "utils/Database.hpp"
#include "services/Authenticator.hpp"
#include "services/CharacterManager.hpp"

class EventHandler {
public:
  EventHandler(NetworkManager& networkManager, 
  Database& database, 
  CharacterManager& characterManager,
  Logger& logger);
  void dispatchEvent(const Event& event, ClientData& clientData);

private:
    void handleAuthentificateClientEvent(const Event& event, ClientData& clientData);
    void handleCreateCharacterEvent(const Event& event, ClientData& clientData);
    void handleGetCharactersListEvent(const Event& event, ClientData& clientData);
    void handleDisconnectClientEvent(const Event& event, ClientData& clientData);
    void handlePingClientEvent(const Event& event, ClientData& clientData);

    NetworkManager& networkManager_;
    Database& database_;
    Logger& logger_;
    CharacterManager& characterManager_;
};