import 'package:flutter/material.dart';

class AnimatedSearchRow extends StatefulWidget {
  final Function(String) onSearch;
  final Function(String) onFilterSelected;

  const AnimatedSearchRow({
    super.key,
    required this.onSearch,
    required this.onFilterSelected,
  });

  @override
  _AnimatedSearchRowState createState() => _AnimatedSearchRowState();
}

class _AnimatedSearchRowState extends State<AnimatedSearchRow> {
  bool _isSearching = false;
  final TextEditingController _controller = TextEditingController();
  String _selectedFilter = 'all';

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _controller.clear();
    });
    // Clear search when closing
    widget.onSearch('');
  }

  void _submitSearch(String value) {
    widget.onSearch(value);
    _cancelSearch();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: FilterChip(
        selected: isSelected,
        selectedColor: Colors.transparent,
        checkmarkColor: Colors.white,
        avatar: value == 'all'
            ? const Icon(Icons.list, size: 16, color: Colors.white)
            : value == 'short'
                ? const Icon(Icons.timer, size: 16, color: Colors.white)
                : const Icon(Icons.timer_outlined,
                    size: 16, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected
                ? Colors.blue.withOpacity(0.5)
                : Colors.blue.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onSelected: (_) {
          setState(() {
            _selectedFilter = value;
          });
          widget.onFilterSelected(value);
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: isSelected ? 4 : 2,
        pressElevation: 8,
        surfaceTintColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.blue.withOpacity(0.3),
        ),
        backgroundColor: isSelected ? Colors.blue.shade400 : Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          AnimatedCrossFade(
            firstChild: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      avatar: const Icon(Icons.search,
                          size: 20, color: Colors.white),
                      color: WidgetStatePropertyAll(Colors.transparent),
                      label: const Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _startSearch,
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    const SizedBox(width: 12),
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 12),
                    _buildFilterChip('< 1 min', 'short'),
                    const SizedBox(width: 12),
                    _buildFilterChip('> 1 min', 'long'),
                  ],
                ),
              ),
            ),
            secondChild: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.blue),
                      ),
                      style: const TextStyle(color: Colors.white),
                      // Remove onSubmitted and add onChanged
                      onChanged: widget.onSearch,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.blue),
                    onPressed: _cancelSearch,
                  ),
                ],
              ),
            ),
            crossFadeState: _isSearching
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
