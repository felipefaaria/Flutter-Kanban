import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Task {
  String id;
  String description;
  String status;

  Task({required this.id, required this.description, required this.status});

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status,
      };

  static Task fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        description: json['description'],
        status: json['status'],
      );
}

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks');
    if (data != null) {
      List<dynamic> decodedData = jsonDecode(data);
      _tasks = decodedData.map((task) => Task.fromJson(task)).toList();
      notifyListeners();
    }
  }

  Future<void> addTask(String description) async {
    final newTask = Task(
      id: (_tasks.length + 1).toString(),
      description: description,
      status: 'to_do',
    );
    _tasks.add(newTask);
    await _saveTasks();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    await _saveTasks();
  }

  Future<void> updateTaskStatus(String id, String status) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      _tasks[taskIndex].status = status;
      await _saveTasks();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', data);
    notifyListeners();
  }
}

// Widget principal do aplicativo
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskProvider()..loadTasks(),
      child: MaterialApp(
        title: 'Kanban App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const KanbanScreen(),
      ),
    );
  }
}

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Kanban'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        color: Colors.grey[200],
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ColumnWidget(
                title: 'A Fazer',
                status: 'to_do',
              ),
            ),
            Expanded(
              child: ColumnWidget(
                title: 'Em Progresso',
                status: 'in_progress',
              ),
            ),
            Expanded(
              child: ColumnWidget(
                title: 'Concluído',
                status: 'done',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final TextEditingController controller = TextEditingController();
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Adicionar Tarefa'),
              content: TextField(
                controller: controller,
                decoration:
                    const InputDecoration(hintText: 'Descrição da Tarefa'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    taskProvider.addTask(controller.text);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          );
        },
        label: const Text('Adicionar Tarefa'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class ColumnWidget extends StatelessWidget {
  final String title;
  final String status;

  const ColumnWidget({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks =
        taskProvider.tasks.where((task) => task.status == status).toList();

    return DragTarget<Task>(
      onAcceptWithDetails: (details) {
        taskProvider.updateTaskStatus(details.data.id, status);
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(50.0),
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(task: tasks[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Draggable<Task>(
      data: task,
      feedback: Material(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              task.description,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
        ),
      ),
      childWhenDragging: Container(),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: InkWell(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 16.0),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    taskProvider.deleteTask(task.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
