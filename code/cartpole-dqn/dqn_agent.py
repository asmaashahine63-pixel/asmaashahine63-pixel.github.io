import gymnasium as gym
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import random
import json
from collections import deque

# ─────────────────────────────────────────────
#  HYPERPARAMETERS
# ─────────────────────────────────────────────
HYPERPARAMS = {
    "learning_rate":       1e-3,
    "gamma":               0.99,
    "epsilon":             1.0,
    "epsilon_min":         0.01,
    "epsilon_decay":       0.995,
    "batch_size":          64,
    "replay_buffer_size":  10_000,
    "target_update_freq":  10,        # episodes
    "num_episodes":        500,
    "max_steps":           500,
}

class QNetwork(nn.Module):

    def __init__(self, state_dim: int, action_dim: int):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 128),
            nn.ReLU(),
            nn.Linear(128, action_dim),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


class ReplayBuffer:

    def __init__(self, capacity: int):
        self.buffer = deque(maxlen=capacity)

    def push(self, state, action, reward, next_state, done):
        self.buffer.append((state, action, reward, next_state, done))

    def sample(self, batch_size: int):
        batch = random.sample(self.buffer, batch_size)
        states, actions, rewards, next_states, dones = zip(*batch)
        return (
            np.array(states,      dtype=np.float32),
            np.array(actions,     dtype=np.int64),
            np.array(rewards,     dtype=np.float32),
            np.array(next_states, dtype=np.float32),
            np.array(dones,       dtype=np.float32),
        )

    def __len__(self):
        return len(self.buffer)


class DQNAgent:
  

    def __init__(self, state_dim: int, action_dim: int, hp: dict, device: torch.device):
        self.action_dim  = action_dim
        self.hp          = hp
        self.device      = device
        self.epsilon     = hp["epsilon"]

        self.policy_net  = QNetwork(state_dim, action_dim).to(device)
        self.target_net  = QNetwork(state_dim, action_dim).to(device)
        self.target_net.load_state_dict(self.policy_net.state_dict())
        self.target_net.eval()

        self.optimizer   = optim.Adam(self.policy_net.parameters(), lr=hp["learning_rate"])
        self.loss_fn     = nn.MSELoss()
        self.buffer      = ReplayBuffer(hp["replay_buffer_size"])


    def select_action(self, state: np.ndarray) -> int:
        if random.random() < self.epsilon:
            return random.randrange(self.action_dim)          # explore
        state_t = torch.tensor(state, dtype=torch.float32).unsqueeze(0).to(self.device)
        with torch.no_grad():
            q_values = self.policy_net(state_t)
        return int(q_values.argmax(dim=1).item())             # exploit

    def store(self, state, action, reward, next_state, done):
        self.buffer.push(state, action, reward, next_state, done)

    def learn(self):
        if len(self.buffer) < self.hp["batch_size"]:
            return None

        states, actions, rewards, next_states, dones = self.buffer.sample(self.hp["batch_size"])

        states_t      = torch.tensor(states,      device=self.device)
        actions_t     = torch.tensor(actions,     device=self.device)
        rewards_t     = torch.tensor(rewards,     device=self.device)
        next_states_t = torch.tensor(next_states, device=self.device)
        dones_t       = torch.tensor(dones,       device=self.device)

        q_current = self.policy_net(states_t).gather(1, actions_t.unsqueeze(1)).squeeze(1)

        with torch.no_grad():
            q_next   = self.target_net(next_states_t).max(dim=1).values
            q_target = rewards_t + self.hp["gamma"] * q_next * (1 - dones_t)

        loss = self.loss_fn(q_current, q_target)
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        return loss.item()

    def update_target(self):
        self.target_net.load_state_dict(self.policy_net.state_dict())

    def decay_epsilon(self):
        self.epsilon = max(self.hp["epsilon_min"], self.epsilon * self.hp["epsilon_decay"])


def train(hp: dict = HYPERPARAMS, render: bool = False, save_path: str = "results.json"):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}\n")

    env = gym.make("CartPole-v1", render_mode="human" if render else None)
    state_dim  = env.observation_space.shape[0]   
    action_dim = env.action_space.n               

    agent = DQNAgent(state_dim, action_dim, hp, device)

    episode_rewards = []
    episode_steps   = []
    losses          = []
    epsilons        = []

    print("─" * 60)
    print(f"  CartPole-v1  |  State dim: {state_dim}  |  Actions: {action_dim}")
    print("─" * 60)

    for episode in range(1, hp["num_episodes"] + 1):
        state, _ = env.reset()
        total_reward = 0
        ep_losses    = []

        for step in range(hp["max_steps"]):
            action              = agent.select_action(state)
            next_state, reward, terminated, truncated, _ = env.step(action)
            done                = terminated or truncated

            agent.store(state, action, reward, next_state, float(done))
            loss = agent.learn()
            if loss is not None:
                ep_losses.append(loss)

            state        = next_state
            total_reward += reward

            if done:
                break

        agent.decay_epsilon()

        if episode % hp["target_update_freq"] == 0:
            agent.update_target()

        episode_rewards.append(total_reward)
        episode_steps.append(step + 1)
        epsilons.append(agent.epsilon)
        losses.append(float(np.mean(ep_losses)) if ep_losses else 0.0)

        window = min(50, episode)
        avg_r  = np.mean(episode_rewards[-window:])

        if episode % 50 == 0 or episode == 1:
            print(f"  Ep {episode:>4d} | Reward {total_reward:>6.1f} | "
                  f"Avg(50) {avg_r:>6.1f} | ε {agent.epsilon:.3f} | "
                  f"Loss {losses[-1]:.4f}")

    env.close()

    results = {
        "hyperparams":       hp,
        "episode_rewards":   episode_rewards,
        "episode_steps":     episode_steps,
        "losses":            losses,
        "epsilons":          epsilons,
        "final_avg_reward":  float(np.mean(episode_rewards[-50:])),
        "success_rate":      float(np.mean([r >= 195 for r in episode_rewards[-100:]])),
    }
    with open(save_path, "w") as f:
        json.dump(results, f, indent=2)

    torch.save(agent.policy_net.state_dict(), "policy_net.pth")
    print(f"\n  ✓ Results saved → {save_path}")
    print(f"  ✓ Model saved   → policy_net.pth")
    print(f"\n  Final avg reward (last 50 eps): {results['final_avg_reward']:.1f}")
    print(f"  Success rate    (last 100 eps): {results['success_rate']*100:.1f}%")

    return results

if __name__ == "__main__":
    train()
