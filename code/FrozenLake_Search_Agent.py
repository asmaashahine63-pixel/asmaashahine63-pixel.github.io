import tkinter as tk
from tkinter import messagebox
from collections import deque
import heapq
import itertools



CUSTOM_MAP = [
    "SFFF",
    "FHFH",
    "FFFH",
    "HFFG"
]

ROWS = 4
COLS = 4

START_STATE = 0
GOAL_STATE = 15
HOLES = {5, 7, 11, 12}

# Action order affects the different paths explored by algorithms
# Action format: action name, change in row, change in column
ACTIONS = [
    ("Down", 1, 0),
    ("Right", 0, 1),
    ("Up", -1, 0),
    ("Left", 0, -1)
]



def state_to_pos(state):
    row = state // COLS
    col = state % COLS
    return row, col


def pos_to_state(row, col):
    return row * COLS + col


def is_valid(row, col):
    if row < 0 or row >= ROWS:
        return False
    if col < 0 or col >= COLS:
        return False

    state = pos_to_state(row, col)

    if state in HOLES:
        return False

    return True


def get_neighbors(state):
    neighbors = []
    row, col = state_to_pos(state)

    for action_name, dr, dc in ACTIONS:
        new_row = row + dr
        new_col = col + dc

        if is_valid(new_row, new_col):
            new_state = pos_to_state(new_row, new_col)
            step_cost = 1
            neighbors.append((new_state, action_name, step_cost))

    return neighbors


def manhattan_distance(state, goal=GOAL_STATE):
    row1, col1 = state_to_pos(state)
    row2, col2 = state_to_pos(goal)

    return abs(row1 - row2) + abs(col1 - col2)


def reconstruct_path(parent, goal):
    path = []
    actions = []

    current = goal

    while current is not None:
        path.append(current)

        previous_data = parent[current]

        if previous_data is None:
            break

        previous_state, action = previous_data
        actions.append(action)
        current = previous_state

    path.reverse()
    actions.reverse()

    return path, actions



def bfs_search():
    queue = deque([START_STATE])
    visited = {START_STATE}
    parent = {START_STATE: None}
    explored = []

    while queue:
        current = queue.popleft()
        explored.append(current)

        if current == GOAL_STATE:
            path, actions = reconstruct_path(parent, GOAL_STATE)
            return path, actions, explored

        for neighbor, action, cost in get_neighbors(current):
            if neighbor not in visited:
                visited.add(neighbor)
                parent[neighbor] = (current, action)
                queue.append(neighbor)

    return None, None, explored


def ucs_search():
    counter = itertools.count()
    priority_queue = []

    heapq.heappush(priority_queue, (0, next(counter), START_STATE))

    parent = {START_STATE: None}
    cost_so_far = {START_STATE: 0}
    explored = []

    while priority_queue:
        current_cost, _, current = heapq.heappop(priority_queue)
        explored.append(current)

        if current == GOAL_STATE:
            path, actions = reconstruct_path(parent, GOAL_STATE)
            return path, actions, explored

        for neighbor, action, step_cost in get_neighbors(current):
            new_cost = current_cost + step_cost

            if neighbor not in cost_so_far or new_cost < cost_so_far[neighbor]:
                cost_so_far[neighbor] = new_cost
                parent[neighbor] = (current, action)
                heapq.heappush(priority_queue, (new_cost, next(counter), neighbor))

    return None, None, explored


def dfs_search():
    stack = [START_STATE]
    visited = set()
    parent = {START_STATE: None}
    explored = []

    while stack:
        current = stack.pop()

        if current in visited:
            continue

        visited.add(current)
        explored.append(current)

        if current == GOAL_STATE:
            path, actions = reconstruct_path(parent, GOAL_STATE)
            return path, actions, explored

        neighbors = get_neighbors(current)

        for neighbor, action, cost in reversed(neighbors):
            if neighbor not in visited:
                if neighbor not in parent:
                    parent[neighbor] = (current, action)
                stack.append(neighbor)

    return None, None, explored


def dls_search(limit=6):
    explored = []
    parent = {START_STATE: None}

    def recursive_dls(current, depth, visited_path):
        explored.append(current)

        if current == GOAL_STATE:
            return True

        if depth == limit:
            return False

        visited_path.add(current)

        for neighbor, action, cost in get_neighbors(current):
            if neighbor not in visited_path:
                parent[neighbor] = (current, action)

                found = recursive_dls(neighbor, depth + 1, visited_path)

                if found:
                    return True

        visited_path.remove(current)
        return False

    found = recursive_dls(START_STATE, 0, set())

    if found:
        path, actions = reconstruct_path(parent, GOAL_STATE)
        return path, actions, explored

    return None, None, explored


def ids_search(max_depth=20):
    total_explored = []

    for depth in range(max_depth + 1):
        path, actions, explored = dls_search(limit=depth)
        total_explored.extend(explored)

        if path is not None:
            return path, actions, total_explored, depth

    return None, None, total_explored, None


def gbfs_search():
    counter = itertools.count()
    priority_queue = []

    heapq.heappush(
        priority_queue,
        (manhattan_distance(START_STATE), next(counter), START_STATE)
    )

    parent = {START_STATE: None}
    visited = set()
    explored = []

    while priority_queue:
        h_value, _, current = heapq.heappop(priority_queue)

        if current in visited:
            continue

        visited.add(current)
        explored.append(current)

        if current == GOAL_STATE:
            path, actions = reconstruct_path(parent, GOAL_STATE)
            return path, actions, explored

        for neighbor, action, cost in get_neighbors(current):
            if neighbor not in visited:
                if neighbor not in parent:
                    parent[neighbor] = (current, action)

                priority = manhattan_distance(neighbor)
                heapq.heappush(priority_queue, (priority, next(counter), neighbor))

    return None, None, explored


def a_star_search():
    counter = itertools.count()
    priority_queue = []

    g_cost = {START_STATE: 0}
    parent = {START_STATE: None}
    explored = []
    visited = set()

    f_start = manhattan_distance(START_STATE)
    heapq.heappush(priority_queue, (f_start, next(counter), START_STATE))

    while priority_queue:
        f_value, _, current = heapq.heappop(priority_queue)

        if current in visited:
            continue

        visited.add(current)
        explored.append(current)

        if current == GOAL_STATE:
            path, actions = reconstruct_path(parent, GOAL_STATE)
            return path, actions, explored

        for neighbor, action, step_cost in get_neighbors(current):
            new_g_cost = g_cost[current] + step_cost

            if neighbor not in g_cost or new_g_cost < g_cost[neighbor]:
                g_cost[neighbor] = new_g_cost
                parent[neighbor] = (current, action)

                h_cost = manhattan_distance(neighbor)
                f_cost = new_g_cost + h_cost

                heapq.heappush(priority_queue, (f_cost, next(counter), neighbor))

    return None, None, explored



class FrozenLakeSearchGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("FrozenLake Search Strategies Agent")

        self.cell_size = 105

        self.current_state = START_STATE
        self.selected_algorithm = ""
        self.path = []
        self.actions = []
        self.explored = []

        self.explored_displayed = []
        self.path_displayed = []

        self.explore_index = 0
        self.path_index = 0
        self.agent_index = 0

        self.is_animating = False

        self.root.configure(bg="#eaf7ff")

        title_label = tk.Label(
            root,
            text="FrozenLake Search Strategies Agent",
            font=("Arial", 18, "bold"),
            bg="#eaf7ff",
            fg="#023047"
        )
        title_label.pack(pady=6)

        subtitle_label = tk.Label(
            root,
            text="Press an algorithm icon. The agent will search automatically and show the difference.",
            font=("Arial", 11),
            bg="#eaf7ff",
            fg="#023047"
        )
        subtitle_label.pack(pady=2)

        self.canvas = tk.Canvas(
            root,
            width=COLS * self.cell_size,
            height=ROWS * self.cell_size,
            bg="#eaf7ff",
            highlightthickness=0
        )
        self.canvas.pack(pady=8)

        self.info_label = tk.Label(
            root,
            text="Choose a search strategy.",
            font=("Arial", 12, "bold"),
            bg="#eaf7ff",
            fg="#023047"
        )
        self.info_label.pack(pady=4)

        self.status_label = tk.Label(
            root,
            text="State: 0 | Steps: 0 | Cost: 0",
            font=("Arial", 11),
            bg="#eaf7ff",
            fg="#023047"
        )
        self.status_label.pack(pady=3)

        self.create_algorithm_icon_buttons()

        self.result_text = tk.Text(
            root,
            height=9,
            width=70,
            font=("Consolas", 10),
            bg="white",
            fg="#023047"
        )
        self.result_text.pack(pady=8)

        self.legend_label = tk.Label(
            root,
            text="Legend: Purple = explored states | Green = final path | Red = agent",
            font=("Arial", 10, "bold"),
            bg="#eaf7ff",
            fg="#023047"
        )
        self.legend_label.pack(pady=3)

        self.draw_grid()


    def create_algorithm_icon_buttons(self):
        button_frame = tk.Frame(self.root, bg="#eaf7ff")
        button_frame.pack(pady=8)

        algorithms = [
            ("🌊", "BFS", "Breadth-First Search"),
            ("💰", "UCS", "Uniform-Cost Search"),
            ("🌲", "DFS", "Depth-First Search"),
            ("📏", "DLS", "Depth-Limited Search"),
            ("🔁", "IDS", "Iterative Deepening Search"),
            ("🧲", "GBFS", "Greedy Best-First Search"),
            ("⭐", "A*", "A* Search")
        ]

        for index, (icon, short_name, full_name) in enumerate(algorithms):
            button = tk.Button(
                button_frame,
                text=f"{icon}\n{short_name}",
                width=9,
                height=3,
                font=("Arial", 10, "bold"),
                bg="#ffffff",
                fg="#023047",
                command=lambda name=short_name: self.run_algorithm_by_icon(name)
            )
            button.grid(row=0, column=index, padx=4, pady=4)

        reset_button = tk.Button(
            self.root,
            text="Reset Game",
            width=16,
            font=("Arial", 11, "bold"),
            bg="#f1faee",
            fg="#023047",
            command=self.reset_game
        )
        reset_button.pack(pady=4)



    def draw_grid(self):
        self.canvas.delete("all")

        for row in range(ROWS):
            for col in range(COLS):
                state = pos_to_state(row, col)
                tile = CUSTOM_MAP[row][col]

                x1 = col * self.cell_size
                y1 = row * self.cell_size
                x2 = x1 + self.cell_size
                y2 = y1 + self.cell_size

                if tile == "S":
                    color = "#b7e4c7"
                    label = "START"
                    icon = "🏠"
                elif tile == "F":
                    color = "#e8f7ff"
                    label = "ICE"
                    icon = "❄"
                elif tile == "H":
                    color = "#48cae4"
                    label = "HOLE"
                    icon = "💧"
                elif tile == "G":
                    color = "#ffd166"
                    label = "GOAL"
                    icon = "🎁"
                else:
                    color = "white"
                    label = ""
                    icon = ""

                if state in self.explored_displayed and tile not in ["H", "S", "G"]:
                    color = "#cdb4db"

                if state in self.path_displayed and tile not in ["H", "S", "G"]:
                    color = "#90be6d"

                if state in self.path_displayed and tile == "G":
                    color = "#90be6d"

                self.canvas.create_rectangle(
                    x1,
                    y1,
                    x2,
                    y2,
                    fill=color,
                    outline="#264653",
                    width=3
                )

                if tile == "F":
                    for i in range(3):
                        self.canvas.create_line(
                            x1 + 18,
                            y1 + 25 + i * 24,
                            x2 - 18,
                            y1 + 10 + i * 24,
                            fill="#bde0fe",
                            width=2
                        )

                self.canvas.create_text(
                    x1 + self.cell_size / 2,
                    y1 + 31,
                    text=icon,
                    font=("Arial", 22)
                )

                self.canvas.create_text(
                    x1 + self.cell_size / 2,
                    y1 + 73,
                    text=label,
                    font=("Arial", 11, "bold"),
                    fill="#023047"
                )

        self.draw_agent()

    def draw_agent(self):
        row, col = state_to_pos(self.current_state)

        x = col * self.cell_size + self.cell_size / 2
        y = row * self.cell_size + self.cell_size / 2

        self.canvas.create_oval(
            x - 26,
            y - 26,
            x + 26,
            y + 26,
            fill="#e63946",
            outline="black",
            width=2
        )

        self.canvas.create_text(
            x,
            y,
            text="A",
            font=("Arial", 20, "bold"),
            fill="white"
        )


    def run_algorithm_by_icon(self, algorithm_short_name):
        if self.is_animating:
            return

        self.reset_game(clear_text=True)
        self.selected_algorithm = algorithm_short_name

        if algorithm_short_name == "BFS":
            self.path, self.actions, self.explored = bfs_search()
            algorithm_full_name = "Breadth-First Search (BFS)"
            explanation = "BFS explores level by level. It guarantees the shortest path when all step costs are equal."

        elif algorithm_short_name == "UCS":
            self.path, self.actions, self.explored = ucs_search()
            algorithm_full_name = "Uniform-Cost Search (UCS)"
            explanation = "UCS expands the lowest-cost node first. Here, all costs are 1, so it behaves similarly to BFS."

        elif algorithm_short_name == "DFS":
            self.path, self.actions, self.explored = dfs_search()
            algorithm_full_name = "Depth-First Search (DFS)"
            explanation = "DFS goes deep along one branch before backtracking. It may find a path but does not guarantee the shortest path."

        elif algorithm_short_name == "DLS":
            self.path, self.actions, self.explored = dls_search(limit=6)
            algorithm_full_name = "Depth-Limited Search (DLS), limit = 6"
            explanation = "DLS is DFS with a maximum depth limit. It avoids infinite depth but may fail if the limit is too small."

        elif algorithm_short_name == "IDS":
            self.path, self.actions, self.explored, depth = ids_search(max_depth=20)
            algorithm_full_name = f"Iterative Deepening Search (IDS), found depth = {depth}"
            explanation = "IDS repeats DLS with increasing limits. It combines BFS completeness with DFS memory behavior."

        elif algorithm_short_name == "GBFS":
            self.path, self.actions, self.explored = gbfs_search()
            algorithm_full_name = "Greedy Best-First Search (GBFS)"
            explanation = "GBFS expands the node closest to the goal according to the heuristic only."

        elif algorithm_short_name == "A*":
            self.path, self.actions, self.explored = a_star_search()
            algorithm_full_name = "A* Search"
            explanation = "A* uses total estimated cost f(n)=g(n)+h(n). It balances path cost and distance to goal."

        else:
            return

        if self.path is None:
            messagebox.showwarning("No Path", "No path was found by this algorithm.")
            return

        self.display_results(algorithm_full_name, explanation)

        self.info_label.config(
            text=f"{algorithm_full_name}: showing explored states first..."
        )

        self.is_animating = True
        self.animate_explored_states()


    def animate_explored_states(self):
        if self.explore_index < len(self.explored):
            state = self.explored[self.explore_index]

            if state not in self.explored_displayed:
                self.explored_displayed.append(state)

            self.current_state = state
            self.draw_grid()

            self.status_label.config(
                text=f"Exploring state: {state} | Explored count: {self.explore_index + 1}"
            )

            self.explore_index += 1
            self.root.after(450, self.animate_explored_states)

        else:
            self.info_label.config(
                text=f"{self.selected_algorithm}: explored states finished. Showing final path..."
            )
            self.root.after(700, self.animate_final_path)

    def animate_final_path(self):
        if self.path_index < len(self.path):
            state = self.path[self.path_index]

            if state not in self.path_displayed:
                self.path_displayed.append(state)

            self.current_state = state
            self.draw_grid()

            self.status_label.config(
                text=f"Final path state: {state} | Path step: {self.path_index}"
            )

            self.path_index += 1
            self.root.after(550, self.animate_final_path)

        else:
            self.info_label.config(
                text=f"{self.selected_algorithm}: moving the agent along the solution path..."
            )
            self.current_state = START_STATE
            self.agent_index = 0
            self.root.after(700, self.animate_agent_movement)

    def animate_agent_movement(self):
        if self.agent_index < len(self.path):
            self.current_state = self.path[self.agent_index]
            self.draw_grid()

            if self.agent_index == 0:
                action_text = "Start"
            else:
                action_text = self.actions[self.agent_index - 1]

            self.status_label.config(
                text=f"Action: {action_text} | State: {self.current_state} | "
                     f"Steps: {self.agent_index} | Cost: {self.agent_index}"
            )

            self.agent_index += 1
            self.root.after(700, self.animate_agent_movement)

        else:
            self.is_animating = False

            self.info_label.config(
                text=f"Success! {self.selected_algorithm} reached the goal in {len(self.path) - 1} steps."
            )

            messagebox.showinfo(
                "Search Complete",
                f"{self.selected_algorithm} completed successfully!\n\n"
                f"Path length: {len(self.path) - 1} steps\n"
                f"Explored states: {len(self.explored)}\n"
                f"Path: {self.path}\n"
                f"Actions: {' -> '.join(self.actions)}"
            )



    def display_results(self, algorithm_name, explanation):
        self.result_text.delete("1.0", tk.END)

        self.result_text.insert(tk.END, f"Algorithm: {algorithm_name}\n")
        self.result_text.insert(tk.END, "-" * 65 + "\n")
        self.result_text.insert(tk.END, f"Explanation: {explanation}\n\n")
        self.result_text.insert(tk.END, f"Path states: {self.path}\n")
        self.result_text.insert(tk.END, f"Actions: {' -> '.join(self.actions)}\n")
        self.result_text.insert(tk.END, f"Path length: {len(self.path) - 1} steps\n")
        self.result_text.insert(tk.END, f"Total cost: {len(self.path) - 1}\n")
        self.result_text.insert(tk.END, f"Explored states: {self.explored}\n")
        self.result_text.insert(tk.END, f"Number of explored states: {len(self.explored)}\n")

    def reset_game(self, clear_text=False):
        self.current_state = START_STATE

        self.path = []
        self.actions = []
        self.explored = []

        self.explored_displayed = []
        self.path_displayed = []

        self.explore_index = 0
        self.path_index = 0
        self.agent_index = 0

        self.is_animating = False

        self.info_label.config(
            text="Choose a search strategy."
        )

        self.status_label.config(
            text="State: 0 | Steps: 0 | Cost: 0"
        )

        if not clear_text:
            self.result_text.delete("1.0", tk.END)

        self.draw_grid()




if __name__ == "__main__":
    root = tk.Tk()
    app = FrozenLakeSearchGUI(root)
    root.mainloop()