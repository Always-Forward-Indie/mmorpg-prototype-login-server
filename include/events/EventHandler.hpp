#pragma once
#include "Event.hpp"
#include <string>
#include <boost/asio.hpp>
#include "data/ClientData.hpp"
#include "network/NetworkManager.hpp"
#include "utils/ResponseBuilder.hpp"
#include "utils/Logger.hpp"
#include "utils/DatabasePool.hpp"
#include "services/Authenticator.hpp"
#include "services/CharacterManager.hpp"
#include "services/AccountManager.hpp"

class EventHandler
{
public:
  EventHandler(NetworkManager &networkManager,
               DatabasePool &pool,
               CharacterManager &characterManager,
               Logger &logger);
  void dispatchEvent(const Event &event, ClientData &clientData);

private:
  void handleAuthentificateClientEvent(const Event &event, ClientData &clientData);
  void handleRegisterAccountEvent(const Event &event, ClientData &clientData);
  void handleCreateCharacterEvent(const Event &event, ClientData &clientData);
  void handleGetCharactersListEvent(const Event &event, ClientData &clientData);
  void handleGetCharacterCreationOptionsEvent(const Event &event, ClientData &clientData);
  void handleDeleteCharacterEvent(const Event &event, ClientData &clientData);
  void handleDisconnectClientEvent(const Event &event, ClientData &clientData);
  void handlePingClientEvent(const Event &event, ClientData &clientData);

  NetworkManager &networkManager_;
  DatabasePool &pool_;
  Logger &logger_;
  std::shared_ptr<spdlog::logger> log_;
  CharacterManager &characterManager_;
  AccountManager accountManager_;
};